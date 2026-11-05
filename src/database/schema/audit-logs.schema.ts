import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  jsonb,
  timestamp,
  inet,
  index,
} from 'drizzle-orm/pg-core';

import { users } from './users.schema.js';

export const auditActionEnum = pgEnum('audit_action', [
  'CREATE',
  'UPDATE',
  'DELETE',
  'LOGIN',
  'LOGOUT',
  'COMMAND',
  'STATUS_CHANGE',
]);

export const auditLogs = pgTable(
  'audit_logs',
  {
    id: uuid('id').defaultRandom().primaryKey(),

    userId: uuid('user_id')
      .references(() => users.id),

    action: auditActionEnum('action').notNull(),

    entityType: varchar('entity_type', {
      length: 100,
    }).notNull(),

    entityId: varchar('entity_id', {
      length: 100,
    }),

    oldValues: jsonb('old_values'),

    newValues: jsonb('new_values'),

    ipAddress: inet('ip_address'),

    createdAt: timestamp('created_at', {
      withTimezone: true,
    }).defaultNow().notNull(),
  },
  (table) => [
    index('audit_logs_user_id_idx').on(table.userId),

    index('audit_logs_entity_idx').on(
      table.entityType,
      table.entityId,
    ),

    index('audit_logs_created_at_idx').on(table.createdAt),
  ],
);