
import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  text,
  timestamp,
  index,
  uniqueIndex,
  foreignKey,
  check,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { stations } from './stations.schema.js';
import { ports } from './ports.schema.js';
import { powerBanks } from './power-banks.schema.js';
import { users } from './users.schema.js';

// ==========================================
// ENUMS
// ==========================================

export const maintenanceTargetTypeEnum = pgEnum(
  'maintenance_target_type',
  [
    'STATION',
    'PORT',
    'POWER_BANK',
  ],
);

export const maintenanceTypeEnum = pgEnum(
  'maintenance_type',
  [
    'PREVENTIVE',
    'CORRECTIVE',
    'INSPECTION',
  ],
);

export const maintenancePriorityEnum = pgEnum(
  'maintenance_priority',
  [
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL',
  ],
);

export const maintenanceStatusEnum = pgEnum(
  'maintenance_status',
  [
    'OPEN',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
  ],
);

// ==========================================
// MAINTENANCE RECORDS TABLE
// ==========================================
//
// One record describes one maintenance job on exactly
// one target: a Station, a Port or a Power Bank.
//
// Lifecycle:
//   OPEN         -> ticket created, target untouched
//   IN_PROGRESS  -> target moved into MAINTENANCE
//   COMPLETED    -> target restored
//   CANCELLED    -> ticket closed (target restored if needed)

export const maintenanceRecords = pgTable(
  'maintenance_records',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    targetType: maintenanceTargetTypeEnum('target_type')
      .notNull(),

    // Exactly one target shape is allowed
    // (see maintenance_records_target_shape_check)
    stationId: uuid('station_id')
      .references(() => stations.id),

    portId: uuid('port_id'),

    powerBankId: uuid('power_bank_id')
      .references(() => powerBanks.id),

    maintenanceType: maintenanceTypeEnum('maintenance_type')
      .notNull(),

    priority: maintenancePriorityEnum('priority')
      .default('MEDIUM')
      .notNull(),

    status: maintenanceStatusEnum('status')
      .default('OPEN')
      .notNull(),

    title: varchar('title', { length: 200 }).notNull(),

    description: text('description'),

    resolutionNotes: text('resolution_notes'),

    // Target status captured when work started.
    // Used to restore the target afterwards.
    previousStatus: varchar('previous_status', {
      length: 30,
    }),

    reportedBy: uuid('reported_by')
      .notNull()
      .references(() => users.id),

    assignedTo: uuid('assigned_to')
      .references(() => users.id),

    startedAt: timestamp('started_at', {
      withTimezone: true,
    }),

    completedAt: timestamp('completed_at', {
      withTimezone: true,
    }),

    cancelledAt: timestamp('cancelled_at', {
      withTimezone: true,
    }),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),

    updatedAt: timestamp('updated_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    // Port must belong to the specified station
    foreignKey({
      name: 'maintenance_records_port_station_fk',
      columns: [
        table.stationId,
        table.portId,
      ],
      foreignColumns: [
        ports.stationId,
        ports.id,
      ],
    }),

    // Target columns must match the target type
    check(
      'maintenance_records_target_shape_check',
      sql`(
        ${table.targetType} = 'STATION'
        AND ${table.stationId} IS NOT NULL
        AND ${table.portId} IS NULL
        AND ${table.powerBankId} IS NULL
      ) OR (
        ${table.targetType} = 'PORT'
        AND ${table.stationId} IS NOT NULL
        AND ${table.portId} IS NOT NULL
        AND ${table.powerBankId} IS NULL
      ) OR (
        ${table.targetType} = 'POWER_BANK'
        AND ${table.powerBankId} IS NOT NULL
        AND ${table.stationId} IS NULL
        AND ${table.portId} IS NULL
      )`,
    ),

    // One active maintenance record per target
    uniqueIndex('maintenance_active_station_unique')
      .on(table.stationId)
      .where(
        sql`${table.targetType} = 'STATION'
          AND ${table.status} IN ('OPEN', 'IN_PROGRESS')`,
      ),

    uniqueIndex('maintenance_active_port_unique')
      .on(table.portId)
      .where(
        sql`${table.targetType} = 'PORT'
          AND ${table.status} IN ('OPEN', 'IN_PROGRESS')`,
      ),

    uniqueIndex('maintenance_active_power_bank_unique')
      .on(table.powerBankId)
      .where(
        sql`${table.targetType} = 'POWER_BANK'
          AND ${table.status} IN ('OPEN', 'IN_PROGRESS')`,
      ),

    index('maintenance_records_status_idx')
      .on(table.status),

    index('maintenance_records_station_id_idx')
      .on(table.stationId),

    index('maintenance_records_port_id_idx')
      .on(table.portId),

    index('maintenance_records_power_bank_id_idx')
      .on(table.powerBankId),

    index('maintenance_records_assigned_to_idx')
      .on(table.assignedTo),

    index('maintenance_records_created_at_idx')
      .on(table.createdAt),
  ],
);
