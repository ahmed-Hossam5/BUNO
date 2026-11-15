
import {
  pgEnum,
  pgTable,
  uuid,
  timestamp,
  uniqueIndex,
  foreignKey,
  check,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { users } from './users.schema.js';
import { powerBanks } from './power-banks.schema.js';
import { stations } from './stations.schema.js';
import { ports } from './ports.schema.js';

export const rentalStatusEnum = pgEnum('rental_status', [
  'PENDING',
  'ACTIVE',
  'RETURNED',
  'CANCELLED',
]);

export const rentals = pgTable(
  'rentals',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),

    powerBankId: uuid('power_bank_id')
      .notNull()
      .references(() => powerBanks.id),

    pickupStationId: uuid('pickup_station_id')
      .notNull()
      .references(() => stations.id),

    pickupPortId: uuid('pickup_port_id')
      .notNull(),

    returnStationId: uuid('return_station_id')
      .references(() => stations.id),

    returnPortId: uuid('return_port_id'),

    status: rentalStatusEnum('status')
      .default('PENDING')
      .notNull(),

    startedAt: timestamp('started_at', {
      withTimezone: true,
    }),

    returnedAt: timestamp('returned_at', {
      withTimezone: true,
    }),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    // Pickup port must belong to pickup station
    foreignKey({
      name: 'rentals_pickup_port_station_fk',
      columns: [
        table.pickupStationId,
        table.pickupPortId,
      ],
      foreignColumns: [
        ports.stationId,
        ports.id,
      ],
    }),

    // Return port must belong to return station
    foreignKey({
      name: 'rentals_return_port_station_fk',
      columns: [
        table.returnStationId,
        table.returnPortId,
      ],
      foreignColumns: [
        ports.stationId,
        ports.id,
      ],
    }),

    // Return station and port must both be NULL or both have values
    check(
      'rentals_return_location_pair_check',
      sql`(${table.returnStationId} IS NULL) = (${table.returnPortId} IS NULL)`,
    ),

    // One active rental per user
    uniqueIndex('one_active_rental_per_user')
      .on(table.userId)
      .where(
        sql`${table.status} IN ('PENDING', 'ACTIVE')`,
      ),

    // One active rental per Power Bank
    uniqueIndex('one_active_rental_per_power_bank')
      .on(table.powerBankId)
      .where(
        sql`${table.status} IN ('PENDING', 'ACTIVE')`,
      ),
  ],
);
