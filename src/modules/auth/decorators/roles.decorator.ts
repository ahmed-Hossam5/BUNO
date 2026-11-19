
import { SetMetadata } from '@nestjs/common';

import type { users } from '../../../database/schema/users.schema.js';

export type UserRole = typeof users.$inferSelect.role;

export const ROLES_KEY = 'roles';

// Restricts a route (or controller) to the listed roles.
// SUPER_ADMIN is always allowed by RolesGuard.
// Must be combined with JwtAuthGuard:
//   @UseGuards(JwtAuthGuard, RolesGuard)
export const Roles = (...roles: UserRole[]) =>
  SetMetadata(ROLES_KEY, roles);
