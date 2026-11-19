import request from 'supertest';
import { and, eq } from 'drizzle-orm';

import {
  createTestContext,
  type TestContext,
} from './helpers/test-app.js';

import { auditLogs } from '../src/database/schema/audit-logs.schema.js';
import { stations } from '../src/database/schema/stations.schema.js';
import { ports } from '../src/database/schema/ports.schema.js';
import { powerBanks } from '../src/database/schema/power-banks.schema.js';

describe('Maintenance (e2e)', () => {
  let ctx: TestContext;

  beforeAll(async () => {
    ctx = await createTestContext();
  });

  afterAll(async () => {
    await ctx.close();
  });

  const http = () => request(ctx.app.getHttpServer());

  const stationStatus = async (id: string) =>
    (await ctx.db.select().from(stations).where(eq(stations.id, id)))[0].status;
  const portStatus = async (id: string) =>
    (await ctx.db.select().from(ports).where(eq(ports.id, id)))[0].status;
  const bank = async (id: string) =>
    (await ctx.db.select().from(powerBanks).where(eq(powerBanks.id, id)))[0];

  const open = (
    user: { auth: Record<string, string> },
    targetType: string,
    targetId: string,
    extra: object = {},
  ) =>
    http().post('/maintenance').set(user.auth).send({
      targetType,
      targetId,
      maintenanceType: 'CORRECTIVE',
      title: 'Fix it',
      ...extra,
    });

  it('is restricted to staff', async () => {
    const customer = await ctx.createUser('CUSTOMER');
    const station = await ctx.createStation();

    await http().get('/maintenance').expect(401);
    await http().get('/maintenance').set(customer.auth).expect(403);
    await open(customer, 'STATION', station.id).expect(403);
  });

  it('validates input and targets', async () => {
    const tech = await ctx.createUser('TECHNICIAN');
    const station = await ctx.createStation();

    await open(tech, 'STATION', station.id, { title: '   ' }).expect(400);
    await open(tech, 'TRUCK', station.id).expect(400);
    await open(tech, 'STATION', 'not-a-uuid').expect(400);
    await open(tech, 'STATION', station.id, { priority: 'URGENT' }).expect(400);
    await open(tech, 'STATION', station.id, { bogus: 1 }).expect(400);
    await open(tech, 'STATION', '00000000-0000-4000-8000-000000000000').expect(404);
    // a port id is not a station id
    await open(tech, 'STATION', station.ports[0].id).expect(404);
  });

  describe('station', () => {
    it('OPEN leaves the station alone; start/complete move and restore it', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation('ONLINE');

      const created = await open(tech, 'STATION', station.id, { priority: 'HIGH' }).expect(201);
      const id = created.body.id;
      expect(created.body).toMatchObject({ status: 'OPEN', priority: 'HIGH', reportedBy: tech.id, assignedTo: null });
      expect(await stationStatus(station.id)).toBe('ONLINE');

      // only one active record per target
      await open(tech, 'STATION', station.id).expect(409);

      const started = await http().patch(`/maintenance/${id}/start`).set(tech.auth).expect(200);
      expect(started.body).toMatchObject({ status: 'IN_PROGRESS', assignedTo: tech.id, previousStatus: 'ONLINE' });
      expect(await stationStatus(station.id)).toBe('MAINTENANCE');
      await http().patch(`/maintenance/${id}/start`).set(tech.auth).expect(409);

      // notes are mandatory
      await http().patch(`/maintenance/${id}/complete`).set(tech.auth).send({}).expect(400);
      await http().patch(`/maintenance/${id}/complete`).set(tech.auth).send({ resolutionNotes: 'x', returnPortId: station.ports[0].id }).expect(400);

      const done = await http().patch(`/maintenance/${id}/complete`).set(tech.auth)
        .send({ resolutionNotes: 'Replaced PSU' }).expect(200);
      expect(done.body.status).toBe('COMPLETED');
      expect(done.body.completedAt).toBeTruthy();
      expect(await stationStatus(station.id)).toBe('ONLINE');

      // a new job is possible once the previous one is closed
      await open(tech, 'STATION', station.id).expect(201);

      // audit trail: ticket created/started/completed + two station status changes
      const ticketLogs = await ctx.db.select().from(auditLogs)
        .where(and(eq(auditLogs.entityType, 'maintenance_record'), eq(auditLogs.entityId, id)));
      expect(ticketLogs).toHaveLength(3);
      const stationLogs = await ctx.db.select().from(auditLogs)
        .where(and(eq(auditLogs.entityType, 'station'), eq(auditLogs.entityId, station.id)));
      expect(stationLogs.map((l) => (l.newValues as { status: string }).status)).toEqual(['MAINTENANCE', 'ONLINE']);
    });

    it('an OFFLINE station returns to OFFLINE unless overridden', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const a = await ctx.createStation('OFFLINE');
      const b = await ctx.createStation('OFFLINE');

      for (const [s, after, expected] of [[a, undefined, 'OFFLINE'], [b, 'ONLINE', 'ONLINE']] as const) {
        const t = await open(tech, 'STATION', s.id).expect(201);
        await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);
        await http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth)
          .send({ resolutionNotes: 'ok', ...(after && { stationStatusAfter: after }) }).expect(200);
        expect(await stationStatus(s.id)).toBe(expected);
      }
    });

    it('is blocked while the station has an active device command', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();

      await http().post('/device-commands').set(tech.auth).send({
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      }).expect(201);

      const t = await open(tech, 'STATION', station.id).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(409);
      expect(await stationStatus(station.id)).toBe('ONLINE');
    });

    it('cancelling an IN_PROGRESS job restores the station', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation('ONLINE');
      const t = await open(tech, 'STATION', station.id).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);

      const res = await http().patch(`/maintenance/${t.body.id}/cancel`).set(tech.auth).send({ reason: 'False alarm' }).expect(200);
      expect(res.body).toMatchObject({ status: 'CANCELLED', resolutionNotes: 'False alarm' });
      expect(await stationStatus(station.id)).toBe('ONLINE');
    });
  });

  describe('port', () => {
    it('empty port: MAINTENANCE then EMPTY; occupied port is refused', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      await ctx.createPlacedPowerBank(station.ports[1].id);

      const occupied = await open(tech, 'PORT', station.ports[1].id).expect(201);
      await http().patch(`/maintenance/${occupied.body.id}/start`).set(tech.auth).expect(409);
      expect(await portStatus(station.ports[1].id)).toBe('OCCUPIED');

      const t = await open(tech, 'PORT', station.ports[0].id).expect(201);
      expect(t.body.stationId).toBe(station.id);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);
      expect(await portStatus(station.ports[0].id)).toBe('MAINTENANCE');

      await http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth)
        .send({ resolutionNotes: 'Cleaned contacts', stationStatusAfter: 'ONLINE' }).expect(400);
      await http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth)
        .send({ resolutionNotes: 'Cleaned contacts' }).expect(200);
      expect(await portStatus(station.ports[0].id)).toBe('EMPTY');
    });

    it('a DISABLED port can be repaired and comes back EMPTY', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      await ctx.db.update(ports).set({ status: 'DISABLED' }).where(eq(ports.id, station.ports[2].id));

      const t = await open(tech, 'PORT', station.ports[2].id).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);
      await http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth).send({ resolutionNotes: 'fixed' }).expect(200);
      expect(await portStatus(station.ports[2].id)).toBe('EMPTY');
    });
  });

  describe('power bank', () => {
    it('takes the bank out of its port and puts it back with movements recorded', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      const bankId = await ctx.createPlacedPowerBank(station.ports[0].id);

      const t = await open(tech, 'POWER_BANK', bankId).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);

      let b = await bank(bankId);
      expect(b).toMatchObject({ status: 'MAINTENANCE', currentPortId: null });
      expect(await portStatus(station.ports[0].id)).toBe('EMPTY');

      // return into a different, empty port
      await http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth)
        .send({ resolutionNotes: 'Battery replaced', returnPortId: station.ports[1].id }).expect(200);

      b = await bank(bankId);
      expect(b).toMatchObject({ status: 'AVAILABLE', currentPortId: station.ports[1].id });
      expect(await portStatus(station.ports[1].id)).toBe('OCCUPIED');
      expect(await ctx.movementsOf(bankId)).toEqual(['INITIAL_PLACEMENT', 'MAINTENANCE_OUT', 'MAINTENANCE_RETURN']);
    });

    it('rolls everything back if the return port is unusable', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      const bankId = await ctx.createPlacedPowerBank(station.ports[0].id);
      await ctx.createPlacedPowerBank(station.ports[1].id); // occupies port 2

      const t = await open(tech, 'POWER_BANK', bankId).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);

      const complete = (returnPortId: string) =>
        http().patch(`/maintenance/${t.body.id}/complete`).set(tech.auth)
          .send({ resolutionNotes: 'done', returnPortId });

      await complete('00000000-0000-4000-8000-000000000000').expect(404);
      await complete(station.ports[1].id).expect(409); // occupied

      // nothing changed: still IN_PROGRESS and the bank is still out
      const row = (await http().get(`/maintenance/${t.body.id}`).set(tech.auth)).body;
      expect(row.status).toBe('IN_PROGRESS');
      expect((await bank(bankId)).status).toBe('MAINTENANCE');
      expect(await ctx.movementsOf(bankId)).toEqual(['INITIAL_PLACEMENT', 'MAINTENANCE_OUT']);
    });

    it('cancelling in progress returns the bank to stock without a port', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      const bankId = await ctx.createPlacedPowerBank(station.ports[0].id);

      const t = await open(tech, 'POWER_BANK', bankId).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(200);
      await http().patch(`/maintenance/${t.body.id}/cancel`).set(tech.auth).send({}).expect(200);

      expect(await bank(bankId)).toMatchObject({ status: 'AVAILABLE', currentPortId: null });
    });

    it('only AVAILABLE banks can enter maintenance', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      const bankId = await ctx.createPlacedPowerBank(station.ports[0].id);
      await ctx.db.update(powerBanks).set({ status: 'RENTED' }).where(eq(powerBanks.id, bankId));

      const t = await open(tech, 'POWER_BANK', bankId).expect(201);
      await http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth).expect(409);
    });
  });

  describe('assignment and permissions', () => {
    it('a technician cannot take a job assigned to someone else; admin can reassign', async () => {
      const techA = await ctx.createUser('TECHNICIAN');
      const techB = await ctx.createUser('TECHNICIAN');
      const admin = await ctx.createUser('ADMIN');
      const customer = await ctx.createUser('CUSTOMER');
      const station = await ctx.createStation();

      const t = await open(techA, 'STATION', station.id).expect(201);
      const id = t.body.id;

      await http().patch(`/maintenance/${id}/assign`).set(techA.auth).send({ assignedTo: techA.id }).expect(403);
      await http().patch(`/maintenance/${id}/assign`).set(admin.auth).send({ assignedTo: customer.id }).expect(400);
      await http().patch(`/maintenance/${id}/assign`).set(admin.auth).send({ assignedTo: '00000000-0000-4000-8000-000000000000' }).expect(404);
      await http().patch(`/maintenance/${id}/assign`).set(admin.auth).send({ assignedTo: techA.id }).expect(200);

      await http().patch(`/maintenance/${id}/start`).set(techB.auth).expect(403);
      expect(await stationStatus(station.id)).toBe('ONLINE');

      await http().patch(`/maintenance/${id}/start`).set(techA.auth).expect(200);
      await http().patch(`/maintenance/${id}/complete`).set(techB.auth).send({ resolutionNotes: 'x' }).expect(403);
      await http().patch(`/maintenance/${id}/complete`).set(admin.auth).send({ resolutionNotes: 'done by admin' }).expect(200);
    });

    it('cancel rules: reporter may cancel OPEN, idempotent, COMPLETED is final', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const other = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();

      const t = await open(tech, 'STATION', station.id).expect(201);
      await http().patch(`/maintenance/${t.body.id}/cancel`).set(other.auth).send({}).expect(403);
      await http().patch(`/maintenance/${t.body.id}/cancel`).set(tech.auth).send({}).expect(200);
      await http().patch(`/maintenance/${t.body.id}/cancel`).set(tech.auth).send({}).expect(200);

      const t2 = await open(tech, 'STATION', station.id).expect(201);
      await http().patch(`/maintenance/${t2.body.id}/start`).set(tech.auth).expect(200);
      await http().patch(`/maintenance/${t2.body.id}/complete`).set(tech.auth).send({ resolutionNotes: 'ok' }).expect(200);
      await http().patch(`/maintenance/${t2.body.id}/cancel`).set(tech.auth).send({}).expect(409);
      await http().patch(`/maintenance/${t2.body.id}/start`).set(tech.auth).expect(409);
    });

    it('two simultaneous starts: exactly one wins', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();
      const t = await open(tech, 'STATION', station.id).expect(201);

      const results = await Promise.all(
        Array.from({ length: 5 }, () => http().patch(`/maintenance/${t.body.id}/start`).set(tech.auth)),
      );
      const codes = results.map((r) => r.status).sort((a, b) => a - b);
      expect(codes.filter((c) => c === 200)).toHaveLength(1);
      expect(codes.filter((c) => c === 409)).toHaveLength(4);
      expect(await stationStatus(station.id)).toBe('MAINTENANCE');
    });

    it('two simultaneous reports for the same target: exactly one wins', async () => {
      const tech = await ctx.createUser('TECHNICIAN');
      const station = await ctx.createStation();

      const results = await Promise.all(
        Array.from({ length: 5 }, () => open(tech, 'STATION', station.id)),
      );
      const codes = results.map((r) => r.status).sort((a, b) => a - b);
      expect(codes.filter((c) => c === 201)).toHaveLength(1);
      expect(codes.filter((c) => c === 409)).toHaveLength(4);
    });
  });

  it('lists with filters and exposes people', async () => {
    const tech = await ctx.createUser('TECHNICIAN');
    const station = await ctx.createStation();
    await open(tech, 'PORT', station.ports[0].id, { priority: 'CRITICAL' }).expect(201);

    const res = await http().get('/maintenance').query({ targetId: station.ports[0].id, priority: 'CRITICAL' }).set(tech.auth).expect(200);
    expect(res.body.meta.total).toBe(1);
    expect(res.body.data[0].reporter.id).toBe(tech.id);
    expect(res.body.data[0].assignee).toBeNull();

    await http().get('/maintenance').query({ limit: 1000 }).set(tech.auth).expect(400);
    await http().get('/maintenance/00000000-0000-4000-8000-000000000000').set(tech.auth).expect(404);
  });
});
