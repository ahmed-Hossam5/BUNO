
import {
  pgEnum,
  pgTable,
  uuid,
  timestamp,
  text,
  index,
  uniqueIndex,
  foreignKey,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { transferMissions } from './transfer-missions.schema.js';
import { powerBanks } from './power-banks.schema.js';
import { ports } from './ports.schema.js';

export const transferMissionItemStatusEnum = pgEnum(
  'transfer_mission_item_status',
  [
    'PENDING',
    'IN_TRANSIT',
    'COMPLETED',
    'FAILED',
    'CANCELLED',
  ],
);

export const transferMissionItems = pgTable(
  'transfer_mission_items',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    missionId: uuid('mission_id').notNull(),

    powerBankId: uuid('power_bank_id')
      .notNull()
      .references(() => powerBanks.id),

    fromStationId: uuid('from_station_id').notNull(),

    fromPortId: uuid('from_port_id').notNull(),

    toStationId: uuid('to_station_id').notNull(),

    toPortId: uuid('to_port_id'),

    status: transferMissionItemStatusEnum('status')
      .default('PENDING')
      .notNull(),

    removedAt: timestamp('removed_at', {
      withTimezone: true,
    }),

    receivedAt: timestamp('received_at', {
      withTimezone: true,
    }),

    failureReason: text('failure_reason'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),

    updatedAt: timestamp('updated_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    // 1. Ensure source station belongs to the mission
    foreignKey({
      name: 'transfer_items_mission_source_fk',
      columns: [table.missionId, table.fromStationId],
      foreignColumns: [
        transferMissions.id,
        transferMissions.sourceStationId,
      ],
    }),

    // 2. Ensure destination station belongs to the mission
    foreignKey({
      name: 'transfer_items_mission_destination_fk',
      columns: [table.missionId, table.toStationId],
      foreignColumns: [
        transferMissions.id,
        transferMissions.destinationStationId,
      ],
    }),

    // 3. Ensure source port belongs to source station
    foreignKey({
      name: 'transfer_items_from_port_station_fk',
      columns: [table.fromStationId, table.fromPortId],
      foreignColumns: [ports.stationId, ports.id],
    }),

    // 4. Ensure destination port belongs to destination station
    foreignKey({
      name: 'transfer_items_to_port_station_fk',
      columns: [table.toStationId, table.toPortId],
      foreignColumns: [ports.stationId, ports.id],
    }),

    uniqueIndex('transfer_mission_items_mission_power_bank_unique')
      .on(table.missionId, table.powerBankId),

    uniqueIndex('transfer_mission_items_active_power_bank_unique')
      .on(table.powerBankId)
      .where(
        sql`${table.status} IN ('PENDING', 'IN_TRANSIT', 'FAILED')`,
      ),

    index('transfer_mission_items_mission_id_idx')
      .on(table.missionId),

    index('transfer_mission_items_power_bank_id_idx')
      .on(table.powerBankId),
  ],
);
