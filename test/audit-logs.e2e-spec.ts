import request from 'supertest';
import { sql } from 'drizzle-orm';

import {
  createTestContext,
  type TestContext,
} from './helpers/test-app.js';

import { AuditLogsService } from '../src/modules/audit-logs/audit-logs.service.js';
import { auditLogs } from '../src/database/schema/audit-logs.schema.js';
import { getPgErrorCode } from '../src/database/database-errors.js';

describe('Audit logs (e2e)', () => {
  let ctx: TestContext;
  let service: AuditLogsService;

  beforeAll(async () => {
    ctx = await createTestContext();
    service = ctx.app.get(AuditLogsService);
  });

  afterAll(async () => {
    await ctx.close();
  });

  const http = () => request(ctx.app.getHttpServer());

  it('requires authentication', async () => {
    await http().get('/audit-logs').expect(401);
  });

  it('is forbidden for CUSTOMER and TECHNICIAN, allowed for ADMIN and SUPER_ADMIN', async () => {
    const customer = await ctx.createUser('CUSTOMER');
    const tech = await ctx.createUser('TECHNICIAN');
    const admin = await ctx.createUser('ADMIN');
    const root = await ctx.createUser('SUPER_ADMIN');

    await http().get('/audit-logs').set(customer.auth).expect(403);
    await http().get('/audit-logs').set(tech.auth).expect(403);
    await http().get('/audit-logs').set(admin.auth).expect(200);
    await http().get('/audit-logs').set(root.auth).expect(200);
  });

  it('records, filters and paginates entries', async () => {
    const admin = await ctx.createUser('ADMIN');
    const entityType = `probe_${Date.now()}`;

    for (let i = 0; i < 3; i++) {
      await service.record({
        userId: admin.id,
        action: 'CREATE',
        entityType,
        entityId: `id-${i}`,
        newValues: { i },
        ipAddress: '10.0.0.7',
      });
    }

    const res = await http()
      .get('/audit-logs')
      .query({ entityType, limit: 2 })
      .set(admin.auth)
      .expect(200);

    expect(res.body.meta).toMatchObject({
      total: 3,
      limit: 2,
      totalPages: 2,
      hasNextPage: true,
    });
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].actor.email).toContain('@test.buno');
    expect(res.body.data[0].ipAddress).toBe('10.0.0.7');

    const one = await http()
      .get(`/audit-logs/${res.body.data[0].id}`)
      .set(admin.auth)
      .expect(200);
    expect(one.body.entityType).toBe(entityType);

    await http()
      .get('/audit-logs/00000000-0000-4000-8000-000000000000')
      .set(admin.auth)
      .expect(404);
  });

  it('rejects bad filters', async () => {
    const admin = await ctx.createUser('ADMIN');

    await http()
      .get('/audit-logs')
      .query({ action: 'HACK' })
      .set(admin.auth)
      .expect(400);

    await http()
      .get('/audit-logs')
      .query({ from: '2030-01-02', to: '2030-01-01' })
      .set(admin.auth)
      .expect(400);

    await http()
      .get('/audit-logs')
      .query({ unknown: 'x' })
      .set(admin.auth)
      .expect(400);
  });

  it('redacts secrets before storing', async () => {
    const entityType = `redact_${Date.now()}`;

    await service.record({
      action: 'UPDATE',
      entityType,
      oldValues: { passwordHash: 'abc', name: 'a' },
      newValues: {
        fcmToken: 'zzz',
        nested: { refreshToken: 'q', ok: 1 },
        list: [{ apiKey: 'k' }],
        when: new Date('2030-01-01T00:00:00Z'),
      },
    });

    const [row] = await ctx.db
      .select()
      .from(auditLogs)
      .where(sql`${auditLogs.entityType} = ${entityType}`);

    expect(row.oldValues).toEqual({
      passwordHash: '[REDACTED]',
      name: 'a',
    });
    expect(row.newValues).toEqual({
      fcmToken: '[REDACTED]',
      nested: { refreshToken: '[REDACTED]', ok: 1 },
      list: [{ apiKey: '[REDACTED]' }],
      when: '2030-01-01T00:00:00.000Z',
    });
  });

  it('is append-only at database level', async () => {
    const entityType = `immutable_${Date.now()}`;
    await service.record({ action: 'CREATE', entityType });

    let updateCode: string | undefined;
    try {
      await ctx.db.execute(
        sql`UPDATE audit_logs SET entity_type = 'x' WHERE entity_type = ${entityType}`,
      );
    } catch (error) {
      updateCode = getPgErrorCode(error);
    }
    expect(updateCode).toBe('55000');

    let deleteCode: string | undefined;
    try {
      await ctx.db.execute(
        sql`DELETE FROM audit_logs WHERE entity_type = ${entityType}`,
      );
    } catch (error) {
      deleteCode = getPgErrorCode(error);
    }
    expect(deleteCode).toBe('55000');
  });

  it('rolls the audit row back together with a failed transaction', async () => {
    const entityType = `rollback_${Date.now()}`;

    await expect(
      ctx.db.transaction(async (tx) => {
        await service.record(
          { action: 'CREATE', entityType },
          tx,
        );
        throw new Error('boom');
      }),
    ).rejects.toThrow('boom');

    const rows = await ctx.db
      .select()
      .from(auditLogs)
      .where(sql`${auditLogs.entityType} = ${entityType}`);

    expect(rows).toHaveLength(0);
  });
});
