import request from 'supertest';
import { and, eq } from 'drizzle-orm';

import {
  createTestContext,
  DEVICE_KEY,
  type TestContext,
} from './helpers/test-app.js';

import { DeviceCommandsService } from '../src/modules/device-commands/device-commands.service.js';
import { deviceCommands } from '../src/database/schema/device-commands.schema.js';
import { auditLogs } from '../src/database/schema/audit-logs.schema.js';
import { stations } from '../src/database/schema/stations.schema.js';
import { getPgErrorCode } from '../src/database/database-errors.js';

describe('Device commands (e2e)', () => {
  let ctx: TestContext;
  let service: DeviceCommandsService;

  beforeAll(async () => {
    ctx = await createTestContext();
    service = ctx.app.get(DeviceCommandsService);
  });

  afterAll(async () => {
    await ctx.close();
  });

  const http = () => request(ctx.app.getHttpServer());
  const device = { 'x-device-key': DEVICE_KEY };
  const base = (stationId: string) =>
    `/device/stations/${stationId}/commands`;

  describe('staff API', () => {
    it('requires TECHNICIAN or ADMIN', async () => {
      const station = await ctx.createStation();
      const customer = await ctx.createUser('CUSTOMER');
      const body = {
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      };

      await http().post('/device-commands').send(body).expect(401);
      await http().post('/device-commands').set(customer.auth).send(body).expect(403);
    });

    it('creates a command, sets expiry and writes an audit row', async () => {
      const station = await ctx.createStation();
      const tech = await ctx.createUser('TECHNICIAN');

      const res = await http()
        .post('/device-commands')
        .set(tech.auth)
        .send({
          stationId: station.id,
          commandType: 'UNLOCK_PORT',
          portId: station.ports[0].id,
          ttlSeconds: 120,
          payload: { reason: 'service' },
        })
        .expect(201);

      expect(res.body.status).toBe('PENDING');
      expect(res.body.requestedBy).toBe(tech.id);

      const ttl =
        new Date(res.body.expiresAt).getTime() - Date.now();
      expect(ttl).toBeGreaterThan(100_000);
      expect(ttl).toBeLessThanOrEqual(120_000);

      const logs = await ctx.db
        .select()
        .from(auditLogs)
        .where(
          and(
            eq(auditLogs.entityType, 'device_command'),
            eq(auditLogs.entityId, res.body.id),
          ),
        );
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('COMMAND');
      expect(logs[0].userId).toBe(tech.id);
    });

    it('validates command shape', async () => {
      const station = await ctx.createStation();
      const other = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const post = (b: object) =>
        http().post('/device-commands').set(admin.auth).send(b);

      await post({ stationId: station.id, commandType: 'RESTART_STATION', portId: station.ports[0].id }).expect(400);
      await post({ stationId: station.id, commandType: 'LOCK_PORT' }).expect(400);
      await post({ stationId: station.id, commandType: 'EXPLODE', portId: station.ports[0].id }).expect(400);
      await post({ stationId: station.id, commandType: 'LOCK_PORT', portId: station.ports[0].id, ttlSeconds: 1 }).expect(400);
      await post({ stationId: station.id, commandType: 'LOCK_PORT', portId: station.ports[0].id, extra: 1 }).expect(400);
      // port of another station
      await post({ stationId: station.id, commandType: 'LOCK_PORT', portId: other.ports[0].id }).expect(404);
      await post({ stationId: '00000000-0000-4000-8000-000000000000', commandType: 'RESTART_STATION' }).expect(404);
    });

    it('refuses commands for an OFFLINE station', async () => {
      const station = await ctx.createStation('OFFLINE');
      const admin = await ctx.createUser('ADMIN');

      await http()
        .post('/device-commands')
        .set(admin.auth)
        .send({ stationId: station.id, commandType: 'RESTART_STATION' })
        .expect(409);
    });

    it('allows only one active command per port', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const body = {
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      };

      const first = await http().post('/device-commands').set(admin.auth).send(body).expect(201);
      await http().post('/device-commands').set(admin.auth).send({ ...body, commandType: 'UNLOCK_PORT' }).expect(409);

      // a different port is independent
      await http().post('/device-commands').set(admin.auth).send({ ...body, portId: station.ports[1].id }).expect(201);

      // cancel frees the port
      await http().patch(`/device-commands/${first.body.id}/cancel`).set(admin.auth).expect(200);
      await http().post('/device-commands').set(admin.auth).send(body).expect(201);
    });

    it('serializes concurrent creates for the same port', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const body = {
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[2].id,
      };

      const results = await Promise.all(
        Array.from({ length: 6 }, () =>
          http().post('/device-commands').set(admin.auth).send(body),
        ),
      );

      const codes = results.map((r) => r.status).sort((a, b) => a - b);
      expect(codes.filter((c) => c === 201)).toHaveLength(1);
      expect(codes.filter((c) => c === 409)).toHaveLength(5);
    });

    it('the database itself refuses two active commands on one port', async () => {
      const station = await ctx.createStation();
      const row = {
        stationId: station.id,
        portId: station.ports[0].id,
        commandType: 'LOCK_PORT' as const,
      };

      await ctx.db.insert(deviceCommands).values(row);

      let code: string | undefined;
      try {
        await ctx.db.insert(deviceCommands).values(row);
      } catch (error) {
        code = getPgErrorCode(error);
      }
      expect(code).toBe('23505');

      // finished commands do not count
      await ctx.db.insert(deviceCommands).values({ ...row, portId: station.ports[1].id, status: 'SUCCEEDED' });
      await ctx.db.insert(deviceCommands).values({ ...row, portId: station.ports[1].id, status: 'SUCCEEDED' });
    });

    it('RELEASE_POWER_BANK needs an occupied port and an ONLINE station', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const release = (portId: string) =>
        http().post('/device-commands').set(admin.auth).send({
          stationId: station.id,
          commandType: 'RELEASE_POWER_BANK',
          portId,
        });

      // empty port
      await release(station.ports[0].id).expect(409);

      // occupied port: powerBankId is resolved automatically
      const bankId = await ctx.createPlacedPowerBank(station.ports[1].id);
      const res = await release(station.ports[1].id).expect(201);
      expect(res.body.powerBankId).toBe(bankId);
      // release uses the short 60s default TTL
      expect(new Date(res.body.expiresAt).getTime() - Date.now()).toBeLessThanOrEqual(60_000);

      // station in maintenance cannot release
      const maint = await ctx.createStation('MAINTENANCE');
      const bank2 = await ctx.createPlacedPowerBank(maint.ports[0].id);
      expect(bank2).toBeTruthy();
      await http().post('/device-commands').set(admin.auth).send({
        stationId: maint.id,
        commandType: 'RELEASE_POWER_BANK',
        portId: maint.ports[0].id,
      }).expect(409);
    });

    it('cancel works only while PENDING and is idempotent', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');

      const created = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'STOP_CHARGING',
        portId: station.ports[0].id,
      }).expect(201);

      await http().patch(`/device-commands/${created.body.id}/cancel`).set(admin.auth).expect(200);
      await http().patch(`/device-commands/${created.body.id}/cancel`).set(admin.auth).expect(200);

      const sent = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'STOP_CHARGING',
        portId: station.ports[0].id,
      }).expect(201);
      await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      await http().patch(`/device-commands/${sent.body.id}/cancel`).set(admin.auth).expect(409);
    });

    it('lists with filters', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'RESTART_STATION',
      }).expect(201);

      const res = await http()
        .get('/device-commands')
        .query({ stationId: station.id, status: 'PENDING' })
        .set(admin.auth)
        .expect(200);

      expect(res.body.meta.total).toBe(1);
      expect(res.body.data[0].commandType).toBe('RESTART_STATION');
    });
  });

  describe('device API', () => {
    it('rejects missing or wrong key', async () => {
      const station = await ctx.createStation();
      await http().post(`${base(station.id)}/poll`).expect(401);
      await http().post(`${base(station.id)}/poll`).set({ 'x-device-key': 'nope' }).expect(401);
    });

    it('runs the full lifecycle: poll -> ack -> result', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');

      const created = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'UNLOCK_PORT',
        portId: station.ports[0].id,
      }).expect(201);
      const { id, commandId } = created.body;

      // poll claims it (PENDING -> SENT)
      const polled = await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      expect(polled.body.commands).toHaveLength(1);
      expect(polled.body.commands[0]).toMatchObject({
        commandId,
        commandType: 'UNLOCK_PORT',
        portNumber: 1,
      });
      let row = (await http().get(`/device-commands/${id}`).set(admin.auth)).body;
      expect(row.status).toBe('SENT');
      expect(row.sentAt).toBeTruthy();

      // un-acked commands are re-delivered
      const again = await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      expect(again.body.commands.map((c: { commandId: string }) => c.commandId)).toEqual([commandId]);

      // ack (idempotent)
      await http().post(`${base(station.id)}/${commandId}/ack`).set(device).expect(200);
      await http().post(`${base(station.id)}/${commandId}/ack`).set(device).expect(200);
      row = (await http().get(`/device-commands/${id}`).set(admin.auth)).body;
      expect(row.status).toBe('ACKNOWLEDGED');

      // acknowledged commands are no longer delivered
      const after = await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      expect(after.body.commands).toHaveLength(0);

      // result
      const done = await http()
        .post(`${base(station.id)}/${commandId}/result`)
        .set(device)
        .send({ success: true, response: { latencyMs: 42 } })
        .expect(200);
      expect(done.body.status).toBe('SUCCEEDED');
      expect(done.body.completedAt).toBeTruthy();
      expect(done.body.response).toEqual({ latencyMs: 42 });

      // same result again = idempotent, conflicting result = 409
      await http().post(`${base(station.id)}/${commandId}/result`).set(device).send({ success: true }).expect(200);
      await http().post(`${base(station.id)}/${commandId}/result`).set(device).send({ success: false }).expect(409);

      // the whole history is audited
      const trail = await ctx.db
        .select()
        .from(auditLogs)
        .where(and(eq(auditLogs.entityType, 'device_command'), eq(auditLogs.entityId, id)))
        .orderBy(auditLogs.createdAt);
      expect(trail.map((l) => (l.newValues as { status?: string } | null)?.status)).toEqual([
        'PENDING', 'SENT', 'ACKNOWLEDGED', 'SUCCEEDED',
      ]);
    });

    it('a FAILED result and result-without-ack both work', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const created = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      }).expect(201);

      await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      const res = await http()
        .post(`${base(station.id)}/${created.body.commandId}/result`)
        .set(device)
        .send({ success: false, response: { error: 'JAMMED' } })
        .expect(200);

      expect(res.body.status).toBe('FAILED');
      expect(res.body.acknowledgedAt).toBeTruthy();
    });

    it('cannot ack or report on a command that was never delivered, or belongs to another station', async () => {
      const station = await ctx.createStation();
      const other = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const created = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      }).expect(201);
      const { commandId } = created.body;

      await http().post(`${base(station.id)}/${commandId}/ack`).set(device).expect(409);
      await http().post(`${base(station.id)}/${commandId}/result`).set(device).send({ success: true }).expect(409);
      await http().post(`${base(other.id)}/${commandId}/ack`).set(device).expect(404);
      await http().post(`${base(station.id)}/${commandId}/result`).set(device).send({}).expect(400);
    });

    it('does not deliver commands to another station', async () => {
      const station = await ctx.createStation();
      const other = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'RESTART_STATION',
      }).expect(201);

      const res = await http().post(`${base(other.id)}/poll`).set(device).expect(200);
      expect(res.body.commands).toHaveLength(0);
      await http().post(`${base('00000000-0000-4000-8000-000000000000')}/poll`).set(device).expect(404);
    });
  });

  describe('expiry', () => {
    it('times out stale commands, frees the port and still accepts a late result', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const body = {
        stationId: station.id,
        commandType: 'LOCK_PORT',
        portId: station.ports[0].id,
      };

      const created = await http().post('/device-commands').set(admin.auth).send(body).expect(201);
      await http().post(`${base(station.id)}/poll`).set(device).expect(200);

      // simulate TTL elapsing
      await ctx.db
        .update(deviceCommands)
        .set({ expiresAt: new Date(Date.now() - 1000) })
        .where(eq(deviceCommands.id, created.body.id));

      // expired commands are not delivered and cannot be acked
      const polled = await http().post(`${base(station.id)}/poll`).set(device).expect(200);
      expect(polled.body.commands).toHaveLength(0);
      const row = (await http().get(`/device-commands/${created.body.id}`).set(admin.auth)).body;
      expect(row.status).toBe('TIMED_OUT');

      // the port is free again
      await http().post('/device-commands').set(admin.auth).send(body).expect(201);

      // the physical outcome reported late is still recorded
      const late = await http()
        .post(`${base(station.id)}/${created.body.commandId}/result`)
        .set(device)
        .send({ success: true })
        .expect(200);
      expect(late.body.status).toBe('SUCCEEDED');

      const trail = await ctx.db
        .select()
        .from(auditLogs)
        .where(and(eq(auditLogs.entityType, 'device_command'), eq(auditLogs.entityId, created.body.id)));
      expect(trail.some((l) => (l.newValues as { lateResult?: boolean } | null)?.lateResult === true)).toBe(true);
    });

    it('sweeper marks expired commands TIMED_OUT', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      const created = await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'RESTART_STATION',
      }).expect(201);

      await ctx.db
        .update(deviceCommands)
        .set({ expiresAt: new Date(Date.now() - 1000) })
        .where(eq(deviceCommands.id, created.body.id));

      expect(await service.expireStaleCommands()).toBeGreaterThanOrEqual(1);

      const row = (await http().get(`/device-commands/${created.body.id}`).set(admin.auth)).body;
      expect(row.status).toBe('TIMED_OUT');
      expect(await service.expireStaleCommands()).toBe(0);
    });

    it('a station set OFFLINE after creation keeps its history intact', async () => {
      const station = await ctx.createStation();
      const admin = await ctx.createUser('ADMIN');
      await http().post('/device-commands').set(admin.auth).send({
        stationId: station.id,
        commandType: 'RESTART_STATION',
      }).expect(201);

      await ctx.db.update(stations).set({ status: 'OFFLINE' }).where(eq(stations.id, station.id));

      const res = await http().get('/device-commands').query({ stationId: station.id }).set(admin.auth).expect(200);
      expect(res.body.meta.total).toBe(1);
    });
  });
});
