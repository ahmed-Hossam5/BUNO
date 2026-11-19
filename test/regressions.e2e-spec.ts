// Regression tests for bugs found while reviewing the project.

import request from 'supertest';

import {
  createTestContext,
  type TestContext,
} from './helpers/test-app.js';

describe('Regressions (e2e)', () => {
  let ctx: TestContext;

  beforeAll(async () => {
    ctx = await createTestContext();
  });

  afterAll(async () => {
    await ctx.close();
  });

  const http = () => request(ctx.app.getHttpServer());

  // drizzle-orm wraps pg errors in DrizzleQueryError, so the old
  // `error.code === '23505'` check never matched and every
  // duplicate produced a 500 instead of a 409.

  it('duplicate station code -> 409 (create)', async () => {
    const stationCode = `DUP-${Date.now()}`;

    await http()
      .post('/stations')
      .send({ stationCode, name: 'A' })
      .expect(201);

    await http()
      .post('/stations')
      .send({ stationCode, name: 'B' })
      .expect(409);
  });

  it('duplicate station code -> 409 (update)', async () => {
    const a = `UPA-${Date.now()}`;
    const b = `UPB-${Date.now()}`;

    await http().post('/stations').send({ stationCode: a, name: 'A' }).expect(201);
    const second = await http()
      .post('/stations')
      .send({ stationCode: b, name: 'B' })
      .expect(201);

    await http()
      .patch(`/stations/${second.body.id}`)
      .send({ stationCode: a })
      .expect(409);
  });

  it('duplicate power bank identifier -> 409', async () => {
    const deviceIdentifier = `PB-DUP-${Date.now()}`;

    await http().post('/power-banks').send({ deviceIdentifier }).expect(201);
    await http().post('/power-banks').send({ deviceIdentifier }).expect(409);
  });

  it('duplicate registration email -> 409', async () => {
    const body = {
      fullName: 'Dup User',
      email: `dup-${Date.now()}@test.buno`,
      password: 'Password123!',
    };

    await http().post('/auth/register').send(body).expect(201);
    await http().post('/auth/register').send(body).expect(409);
  });
});
