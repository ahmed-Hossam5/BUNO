
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { Reflector } from '@nestjs/core';

import {
  ROLES_KEY,
  type UserRole,
} from '../decorators/roles.decorator.js';

import type {
  AuthenticatedUser,
} from '../strategies/jwt.strategy.js';

interface RequestWithUser {
  user?: AuthenticatedUser;
}

// ==========================================
// ROLES GUARD
// ==========================================
//
// Fail-closed: a route protected by RolesGuard
// without any @Roles() metadata is rejected.

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    @Inject(Reflector)
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles =
      this.reflector.getAllAndOverride<
        UserRole[] | undefined
      >(ROLES_KEY, [
        context.getHandler(),
        context.getClass(),
      ]);

    const request = context
      .switchToHttp()
      .getRequest<RequestWithUser>();

    const user = request.user;

    if (!user) {
      throw new UnauthorizedException(
        'Authentication required',
      );
    }

    if (!requiredRoles || requiredRoles.length === 0) {
      throw new ForbiddenException(
        'Route has no role policy',
      );
    }

    if (user.role === 'SUPER_ADMIN') {
      return true;
    }

    if (!requiredRoles.includes(user.role)) {
      throw new ForbiddenException(
        'Insufficient permissions',
      );
    }

    return true;
  }
}
