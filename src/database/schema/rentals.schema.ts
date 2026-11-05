import {
  pgEnum,
  pgTable,
  uuid,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

import { users } from './users.schema.js';
import { powerBanks } from './power-banks.schema.js';
import { stations } from './stations.schema.js';
import { ports } from './ports.schema.js';
import { sql } from 'drizzle-orm';
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
      .notNull()
      .references(() => ports.id),

    returnStationId: uuid('return_station_id')
      .references(() => stations.id),

    returnPortId: uuid('return_port_id')
      .references(() => ports.id),

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
uniqueIndex('one_active_rental_per_user')
  .on(table.userId)
  .where(
    sql`${table.status} IN ('PENDING', 'ACTIVE')`,
  ),
  ],
);