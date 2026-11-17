
import {
  pgEnum,
  pgTable,
  uuid,
  integer,
  varchar,
  text,
  timestamp,
  index,
  uniqueIndex,
  check,
} from 'drizzle-orm/pg-core';

import { sql } from 'drizzle-orm';

import { notifications } from './notifications.schema.js';
import { userDevices } from './user-devices.schema.js';

// ==========================================
// NOTIFICATION DELIVERY STATUS
// ==========================================

export const notificationDeliveryStatusEnum = pgEnum(
  'notification_delivery_status',
  [
    'PENDING',
    'PROCESSING',
    'SENT',
    'FAILED',
    'CANCELLED',
  ],
);

// ==========================================
// NOTIFICATION DELIVERIES TABLE
// ==========================================

export const notificationDeliveries = pgTable(
  'notification_deliveries',
  {
    id: uuid('id')
      .defaultRandom()
      .primaryKey(),

    // Original notification
    notificationId: uuid('notification_id')
      .notNull()
      .references(() => notifications.id, {
        onDelete: 'cascade',
      }),

    // Target device
    userDeviceId: uuid('user_device_id')
      .notNull()
      .references(() => userDevices.id, {
        onDelete: 'restrict',
      }),

    // Delivery status
    status: notificationDeliveryStatusEnum('status')
      .default('PENDING')
      .notNull(),

    // Retry configuration
    attemptCount: integer('attempt_count')
      .default(0)
      .notNull(),

    maxAttempts: integer('max_attempts')
      .default(5)
      .notNull(),

    // Next eligible retry time
    nextAttemptAt: timestamp('next_attempt_at', {
      withTimezone: true,
    })
      .defaultNow()
      .notNull(),

    // Last delivery attempt
    lastAttemptAt: timestamp('last_attempt_at', {
      withTimezone: true,
    }),

    // Processing lease
    lockedUntil: timestamp('locked_until', {
      withTimezone: true,
    }),

    // Successful delivery
    sentAt: timestamp('sent_at', {
      withTimezone: true,
    }),

    // Final failure
    failedAt: timestamp('failed_at', {
      withTimezone: true,
    }),

    // Error information
    lastErrorCode: varchar('last_error_code', {
      length: 100,
    }),

    lastErrorMessage: text('last_error_message'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    })
      .defaultNow()
      .notNull(),

    updatedAt: timestamp('updated_at', {
      withTimezone: true,
    })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    // One delivery record per notification and device
    uniqueIndex(
      'notification_deliveries_notification_device_unique',
    ).on(
      table.notificationId,
      table.userDeviceId,
    ),

    // Find deliveries for a specific device
    index(
      'notification_deliveries_device_id_idx',
    ).on(table.userDeviceId),

    // Find pending deliveries eligible for processing
    index(
      'notification_deliveries_status_next_attempt_idx',
    ).on(
      table.status,
      table.nextAttemptAt,
    ),

    // Retry counters must remain valid
    check(
      'notification_deliveries_attempt_count_check',
      sql`${table.attemptCount} >= 0
        AND ${table.attemptCount} <= ${table.maxAttempts}`,
    ),

    check(
      'notification_deliveries_max_attempts_check',
      sql`${table.maxAttempts} > 0`,
    ),
  ],
);
