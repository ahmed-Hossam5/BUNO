
import {
  pgEnum,
  pgTable,
  uuid,
  timestamp,
  text,
  index,
  uniqueIndex,
  check,
  foreignKey,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { powerBanks } from './power-banks.schema.js';
import { ports } from './ports.schema.js';
import { users } from './users.schema.js';
import { rentals } from './rentals.schema.js';
import { transferMissionItems } from './transfer-mission-items.schema.js';

export const powerBankMovementTypeEnum = pgEnum(
  'power_bank_movement_type',
  [
    'INITIAL_PLACEMENT',
    'RENTAL_PICKUP',
    'RENTAL_RETURN',
    'TRANSFER_OUT',
    'TRANSFER_IN',
    'MAINTENANCE_OUT',
    'MAINTENANCE_RETURN',
  ],
);

export const powerBankMovements = pgTable(
  'power_bank_movements',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    powerBankId: uuid('power_bank_id')
      .notNull()
      .references(() => powerBanks.id),

    // Source location
    fromStationId: uuid('from_station_id'),

    fromPortId: uuid('from_port_id'),

    // Destination location
    toStationId: uuid('to_station_id'),

    toPortId: uuid('to_port_id'),

    performedBy: uuid('performed_by')
      .references(() => users.id),

    movementType: powerBankMovementTypeEnum(
      'movement_type',
    ).notNull(),

    rentalId: uuid('rental_id')
      .references(() => rentals.id),

    transferMissionItemId: uuid('transfer_mission_item_id')
      .references(() => transferMissionItems.id),

    notes: text('notes'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    // Source port must belong to source station
    foreignKey({
      name: 'power_bank_movements_from_port_station_fk',
      columns: [
        table.fromStationId,
        table.fromPortId,
      ],
      foreignColumns: [
        ports.stationId,
        ports.id,
      ],
    }),

    // Destination port must belong to destination station
    foreignKey({
      name: 'power_bank_movements_to_port_station_fk',
      columns: [
        table.toStationId,
        table.toPortId,
      ],
      foreignColumns: [
        ports.stationId,
        ports.id,
      ],
    }),

    index('power_bank_movements_power_bank_id_idx')
      .on(table.powerBankId),

    index('power_bank_movements_performed_by_idx')
      .on(table.performedBy),

    index('power_bank_movements_rental_id_idx')
      .on(table.rentalId),

    index('power_bank_movements_created_at_idx')
      .on(table.createdAt),

    uniqueIndex('power_bank_movements_transfer_item_type_unique')
      .on(
        table.transferMissionItemId,
        table.movementType,
      )
      .where(
        sql`${table.transferMissionItemId} IS NOT NULL`,
      ),

    check(
      'power_bank_movements_from_location_pair_check',
      sql`(${table.fromStationId} IS NULL) = (${table.fromPortId} IS NULL)`,
    ),

    check(
      'power_bank_movements_to_location_pair_check',
      sql`(${table.toStationId} IS NULL) = (${table.toPortId} IS NULL)`,
    ),
  ],
);
