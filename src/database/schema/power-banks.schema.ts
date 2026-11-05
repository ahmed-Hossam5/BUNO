import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  timestamp,
} from 'drizzle-orm/pg-core';

import { ports } from './ports.schema.js';

export const powerBankStatusEnum = pgEnum('power_bank_status', [
  'AVAILABLE',
  'RENTED',
  'MAINTENANCE',
  'LOST',
]);

export const powerBanks = pgTable('power_banks', {
  id: uuid('id').defaultRandom().primaryKey(),

  deviceIdentifier: varchar('device_identifier', {
    length: 100,
  })
    .notNull()
    .unique(),

  status: powerBankStatusEnum('status')
    .default('AVAILABLE')
    .notNull(),

  currentPortId: uuid('current_port_id')
    .unique()
    .references(() => ports.id),

  createdAt: timestamp('created_at', {
    withTimezone: true,
  }).defaultNow().notNull(),

  updatedAt: timestamp('updated_at', {
    withTimezone: true,
  }).defaultNow().notNull(),
});