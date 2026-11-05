import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  integer,
  timestamp,
} from 'drizzle-orm/pg-core';

export const stationStatusEnum = pgEnum('station_status', [
  'ONLINE',
  'OFFLINE',
  'MAINTENANCE',
]);

export const stations = pgTable('stations', {
  id: uuid('id').defaultRandom().primaryKey(),

  stationCode: varchar('station_code', { length: 50 })
    .notNull()
    .unique(),

  name: varchar('name', { length: 150 }).notNull(),

  totalPorts: integer('total_ports').default(4).notNull(),

  status: stationStatusEnum('status')
    .default('OFFLINE')
    .notNull(),

  createdAt: timestamp('created_at', {
    withTimezone: true,
  }).defaultNow().notNull(),

  updatedAt: timestamp('updated_at', {
    withTimezone: true,
  }).defaultNow().notNull(),
});