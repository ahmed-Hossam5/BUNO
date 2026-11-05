import {
  pgEnum,
  pgTable,
  uuid,
  integer,
  timestamp,
  unique,
} from 'drizzle-orm/pg-core';

import { stations } from './stations.schema.js';

export const portStatusEnum = pgEnum('port_status', [
  'EMPTY',
  'OCCUPIED',
  'DISABLED',
  'MAINTENANCE',
]);

export const ports = pgTable(
  'ports',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    stationId: uuid('station_id')
      .notNull()
      .references(() => stations.id, {
        
      }),

    portNumber: integer('port_number').notNull(),

    status: portStatusEnum('status')
      .default('EMPTY')
      .notNull(),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),

    updatedAt: timestamp('updated_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    unique('station_port_number_unique').on(
      table.stationId,
      table.portNumber,
    ),
  ],
);