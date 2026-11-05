import {
  pgEnum,
  pgTable,
  uuid,
  varchar,
  boolean,
  timestamp,
} from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', [
  'CUSTOMER',
  'ADMIN',
  'TECHNICIAN',
  'SUPER_ADMIN',
]);

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),

  fullName: varchar('full_name', { length: 150 }).notNull(),

  email: varchar('email', { length: 255 }).notNull().unique(),

  passwordHash: varchar('password_hash', { length: 255 }).notNull(),

  phone: varchar('phone', { length: 20 }).unique(),

  role: userRoleEnum('role').default('CUSTOMER').notNull(),

  isActive: boolean('is_active').default(true).notNull(),

  createdAt: timestamp('created_at', {
    withTimezone: true,
  }).defaultNow().notNull(),

  updatedAt: timestamp('updated_at', {
    withTimezone: true,
  }).defaultNow().notNull(),
});