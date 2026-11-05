import {
  pgEnum,
  pgTable,
  uuid,
  jsonb,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';

import { stations } from './stations.schema.js';
import { ports } from './ports.schema.js';
import { powerBanks } from './power-banks.schema.js';

export const telemetryEventTypeEnum = pgEnum(
  'telemetry_event_type',
  [
    'HEARTBEAT',
    'BATTERY_UPDATE',
    'TEMPERATURE_UPDATE',
    'PORT_STATUS_UPDATE',
    'CHARGING_UPDATE',
    'ERROR',
  ],
);

export const telemetry = pgTable(
  'telemetry',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    stationId: uuid('station_id')
      .notNull()
      .references(() => stations.id),

    portId: uuid('port_id')
      .references(() => ports.id),

    powerBankId: uuid('power_bank_id')
      .references(() => powerBanks.id),

    eventType: telemetryEventTypeEnum('event_type')
      .notNull(),

    data: jsonb('data').notNull(),

    recordedAt: timestamp('recorded_at', {
      withTimezone: true,
    }).notNull(),

    receivedAt: timestamp('received_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    index('telemetry_station_id_idx').on(table.stationId),

    index('telemetry_power_bank_id_idx').on(table.powerBankId),

    index('telemetry_recorded_at_idx').on(table.recordedAt),
  ],
);