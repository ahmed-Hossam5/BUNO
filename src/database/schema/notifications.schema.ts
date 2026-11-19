import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  text,
  jsonb,
  boolean,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';

import { users } from './users.schema.js';

export const notificationTypeEnum = pgEnum(
  'notification_type',
  [
    'RENTAL_STARTED',
    'RENTAL_RETURNED',
    'RENTAL_FAILED',
    'PAYMENT_SUCCESS',
    'PAYMENT_FAILED',
    'STATION_OFFLINE',
    'SYSTEM_ALERT',
  ],
);

export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),

    type: notificationTypeEnum('type').notNull(),

    title: varchar('title', { length: 200 }).notNull(),

    message: text('message').notNull(),

    data: jsonb('data'),

    isRead: boolean('is_read').default(false).notNull(),

    readAt: timestamp('read_at', {
      withTimezone: true,
    }),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    index('notifications_user_id_idx').on(table.userId),

    index('notifications_created_at_idx').on(table.createdAt),
  ],
);