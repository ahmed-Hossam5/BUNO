import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  timestamp,
  jsonb,
  index,
} from 'drizzle-orm/pg-core';

import { stations } from './stations.schema.js';
import { ports } from './ports.schema.js';
import { powerBanks } from './power-banks.schema.js';
import { users } from './users.schema.js';

export const deviceCommandStatusEnum = pgEnum(
  'device_command_status',
  [
    'PENDING',
    'SENT',
    'ACKNOWLEDGED',
    'SUCCEEDED',
    'FAILED',
    'TIMED_OUT',
    'CANCELLED',
  ],
);

export const deviceCommandTypeEnum = pgEnum(
  'device_command_type',
  [
    'RELEASE_POWER_BANK',
    'STOP_CHARGING',
    'RESTART_STATION',
    'LOCK_PORT',
    'UNLOCK_PORT',
  ],
);

export const deviceCommands = pgTable(
  'device_commands',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    commandId: uuid('command_id')
      .defaultRandom()
      .notNull()
      .unique(),

    stationId: uuid('station_id')
      .notNull()
      .references(() => stations.id),

    portId: uuid('port_id')
      .references(() => ports.id),

    powerBankId: uuid('power_bank_id')
      .references(() => powerBanks.id),

    requestedBy: uuid('requested_by')
      .references(() => users.id),

    commandType: deviceCommandTypeEnum('command_type')
      .notNull(),

    status: deviceCommandStatusEnum('status')
      .default('PENDING')
      .notNull(),

    payload: jsonb('payload'),

    response: jsonb('response'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),

    sentAt: timestamp('sent_at', {
      withTimezone: true,
    }),

    acknowledgedAt: timestamp('acknowledged_at', {
      withTimezone: true,
    }),

    completedAt: timestamp('completed_at', {
      withTimezone: true,
    }),

    expiresAt: timestamp('expires_at', {
      withTimezone: true,
    }),
  },
  (table) => [
    index('device_commands_station_id_idx').on(table.stationId),

    index('device_commands_status_idx').on(table.status),

    index('device_commands_created_at_idx').on(table.createdAt),
  ],
);