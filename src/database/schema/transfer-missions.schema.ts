
import {
  pgEnum,
  pgTable,
  uuid,
  timestamp,
  text,
  index,
  check,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { stations } from './stations.schema.js';
import { users } from './users.schema.js';

export const transferMissionStatusEnum = pgEnum(
  'transfer_mission_status',
  [
    'OPEN',
    'ASSIGNED',
    'IN_PROGRESS',
    'PARTIALLY_COMPLETED',
    'COMPLETED',
    'CANCELLED',
  ],
);

export const transferMissions = pgTable(
  'transfer_missions',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    sourceStationId: uuid('source_station_id')
      .notNull()
      .references(() => stations.id),

    destinationStationId: uuid('destination_station_id')
      .notNull()
      .references(() => stations.id),

    createdBy: uuid('created_by')
      .notNull()
      .references(() => users.id),

    assignedTo: uuid('assigned_to')
      .references(() => users.id),

    status: transferMissionStatusEnum('status')
      .default('OPEN')
      .notNull(),

    acceptedAt: timestamp('accepted_at', {
      withTimezone: true,
    }),

    startedAt: timestamp('started_at', {
      withTimezone: true,
    }),

    completedAt: timestamp('completed_at', {
      withTimezone: true,
    }),

    cancelledAt: timestamp('cancelled_at', {
      withTimezone: true,
    }),

    notes: text('notes'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),

    updatedAt: timestamp('updated_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    index('transfer_missions_status_idx')
      .on(table.status),

    index('transfer_missions_assigned_to_idx')
      .on(table.assignedTo),

    index('transfer_missions_source_station_idx')
      .on(table.sourceStationId),

    index('transfer_missions_destination_station_idx')
      .on(table.destinationStationId),

    // Composite unique keys for mission locations
    uniqueIndex('transfer_missions_id_source_station_unique')
      .on(table.id, table.sourceStationId),

    uniqueIndex('transfer_missions_id_destination_station_unique')
      .on(table.id, table.destinationStationId),

    check(
      'transfer_missions_different_stations',
      sql`${table.sourceStationId} <> ${table.destinationStationId}`,
    ),
  ],
);
