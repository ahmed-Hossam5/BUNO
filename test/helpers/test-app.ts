// Shared harness for the integration tests.
//
// Boots the real modules (guards, JWT strategy, validation pipe)
// against a real PostgreSQL database (DATABASE_URL must point at a
// database where `npm run db:migrate` has been applied).
// Each test creates its own uniquely named data, so suites can run
// against the same database without cleaning it.

import { randomBytes, randomUUID } from 'node:crypto';

import { ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import type { INestApplication } from '@nestjs/common';
import { eq } from 'drizzle-orm';

import { DatabaseModule } from '../../src/database/database.module.js';
import { DATABASE_CONNECTION } from '../../src/database/database.constants.js';
import type { databaseProvider } from '../../src/database/database.provider.js';

import { AuthModule } from '../../src/modules/auth/auth.module.js';
import { StationsModule } from '../../src/modules/stations/stations.module.js';
import { PortsModule } from '../../src/modules/ports/ports.module.js';
import { PowerBanksModule } from '../../src/modules/power-banks/power-banks.module.js';
import { AuditLogsModule } from '../../src/modules/audit-logs/audit-logs.module.js';
import { DeviceCommandsModule } from '../../src/modules/device-commands/device-commands.module.js';
import { MaintenanceModule } from '../../src/modules/maintenance/maintenance.module.js';

import { users } from '../../src/database/schema/users.schema.js';
import { authSessions } from '../../src/database/schema/auth-sessions.schema.js';
import { stations } from '../../src/database/schema/stations.schema.js';
import { ports } from '../../src/database/schema/ports.schema.js';
import { powerBanks } from '../../src/database/schema/power-banks.schema.js';
import { powerBankMovements } from '../../src/database/schema/power-bank-movements.schema.js';

export const DEVICE_KEY = 'test-device-key-0123456789';

type Connection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

export type Role =
  | 'CUSTOMER'
  | 'ADMIN'
  | 'TECHNICIAN'
  | 'SUPER_ADMIN';

export interface TestUser {
  id: string;
  token: string;
  auth: { Authorization: string };
}

export interface TestContext {
  app: INestApplication;
  db: Connection['db'];
  close: () => Promise<void>;
  createUser: (role: Role) => Promise<TestUser>;
  createStation: (
    status?: 'ONLINE' | 'OFFLINE' | 'MAINTENANCE',
  ) => Promise<{
    id: string;
    ports: { id: string; portNumber: number }[];
  }>;
  createPlacedPowerBank: (portId: string) => Promise<string>;
  movementsOf: (powerBankId: string) => Promise<string[]>;
}

export async function createTestContext(): Promise<TestContext> {
  process.env.JWT_ACCESS_SECRET ??= randomBytes(32).toString('hex');
  process.env.DEVICE_API_KEY = DEVICE_KEY;

  const moduleRef = await Test.createTestingModule({
    imports: [
      ConfigModule.forRoot({
        isGlobal: true,
        ignoreEnvFile: true,
      }),
      DatabaseModule,
      AuthModule,
      StationsModule,
      PortsModule,
      PowerBanksModule,
      AuditLogsModule,
      DeviceCommandsModule,
      MaintenanceModule,
    ],
  }).compile();

  const app = moduleRef.createNestApplication();

  // Same pipe as main.ts
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.init();

  const connection = app.get<Connection>(DATABASE_CONNECTION);
  const db = connection.db;
  const jwt = app.get(JwtService);

  const unique = () => randomBytes(5).toString('hex');

  return {
    app,
    db,

    close: () => app.close(),

    async createUser(role) {
      const [user] = await db
        .insert(users)
        .values({
          fullName: `Test ${role} ${unique()}`,
          email: `${unique()}@test.buno`,
          passwordHash: 'not-a-real-hash',
          role,
        })
        .returning({ id: users.id });

      const [session] = await db
        .insert(authSessions)
        .values({
          userId: user.id,
          refreshTokenHash: randomBytes(32).toString('hex'),
          expiresAt: new Date(Date.now() + 3_600_000),
        })
        .returning({ id: authSessions.id });

      const token = jwt.sign({
        sub: user.id,
        sid: session.id,
      });

      return {
        id: user.id,
        token,
        auth: { Authorization: `Bearer ${token}` },
      };
    },

    async createStation(status = 'ONLINE') {
      const [station] = await db
        .insert(stations)
        .values({
          stationCode: `T-${unique()}`,
          name: 'Test station',
          totalPorts: 3,
          status,
        })
        .returning();

      const created = await db
        .insert(ports)
        .values(
          [1, 2, 3].map((portNumber) => ({
            stationId: station.id,
            portNumber,
          })),
        )
        .returning();

      return {
        id: station.id,
        ports: created
          .map((p) => ({
            id: p.id,
            portNumber: p.portNumber,
          }))
          .sort((a, b) => a.portNumber - b.portNumber),
      };
    },

    // Creates a Power Bank and performs the initial placement
    // exactly the way PowerBanksService does it.
    async createPlacedPowerBank(portId) {
      const [bank] = await db
        .insert(powerBanks)
        .values({ deviceIdentifier: `PB-${randomUUID()}` })
        .returning();

      const [port] = await db
        .select()
        .from(ports)
        .where(eq(ports.id, portId));

      await db
        .update(powerBanks)
        .set({ currentPortId: portId })
        .where(eq(powerBanks.id, bank.id));

      await db
        .update(ports)
        .set({ status: 'OCCUPIED' })
        .where(eq(ports.id, portId));

      await db.insert(powerBankMovements).values({
        powerBankId: bank.id,
        toStationId: port.stationId,
        toPortId: portId,
        movementType: 'INITIAL_PLACEMENT',
      });

      return bank.id;
    },

    async movementsOf(powerBankId) {
      const rows = await db
        .select({ type: powerBankMovements.movementType })
        .from(powerBankMovements)
        .where(eq(powerBankMovements.powerBankId, powerBankId))
        .orderBy(powerBankMovements.createdAt);

      return rows.map((r) => r.type);
    },
  };
}
