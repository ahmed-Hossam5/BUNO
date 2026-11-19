
import {
  pgTable,
  uuid,
  varchar,
  timestamp,
  index,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

import { users } from './users.schema.js';

// ==========================================
// AUTH SESSIONS TABLE
// ==========================================

export const authSessions = pgTable(
  'auth_sessions',
  {
    id: uuid('id')
      .defaultRandom()
      .primaryKey(),

    // Session owner
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, {
        onDelete: 'cascade',
      }),

    // SHA-256 hash of refresh token
    refreshTokenHash: varchar(
      'refresh_token_hash',
      { length: 64 },
    ).notNull(),

    // Refresh token expiration
    expiresAt: timestamp('expires_at', {
      withTimezone: true,
    }).notNull(),

    // Revocation information
    revokedAt: timestamp('revoked_at', {
      withTimezone: true,
    }),

    // Last successful refresh
    lastUsedAt: timestamp('last_used_at', {
      withTimezone: true,
    }),

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
    uniqueIndex(
      'auth_sessions_refresh_token_hash_unique',
    ).on(table.refreshTokenHash),

    index(
      'auth_sessions_user_id_idx',
    ).on(table.userId),

    index(
      'auth_sessions_expires_at_idx',
    ).on(table.expiresAt),
  ],
);
