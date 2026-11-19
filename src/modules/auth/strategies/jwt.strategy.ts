
import {
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { ConfigService } from '@nestjs/config';

import { PassportStrategy } from '@nestjs/passport';

import {
  ExtractJwt,
  Strategy,
} from 'passport-jwt';

import {
  and,
  eq,
  gt,
  isNull,
} from 'drizzle-orm';

import {
  DATABASE_CONNECTION,
} from '../../../database/database.constants.js';

import type {
  databaseProvider,
} from '../../../database/database.provider.js';

import {
  users,
} from '../../../database/schema/users.schema.js';

import {
  authSessions,
} from '../../../database/schema/auth-sessions.schema.js';

// ==========================================
// DATABASE TYPE
// ==========================================

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

// ==========================================
// JWT PAYLOAD
// ==========================================

interface JwtPayload {
  sub: string;
  sid: string;
}

// ==========================================
// AUTHENTICATED USER
// ==========================================

export interface AuthenticatedUser {
  userId: string;
  sessionId: string;
  role: typeof users.$inferSelect.role;
}

// ==========================================
// JWT STRATEGY
// ==========================================

@Injectable()
export class JwtStrategy extends PassportStrategy(
  Strategy,
  'jwt',
) {
  constructor(
    configService: ConfigService,

    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {
    super({
      algorithms: ['HS256'],
      jwtFromRequest:
        ExtractJwt.fromAuthHeaderAsBearerToken(),

      ignoreExpiration: false,

      secretOrKey:
        configService.getOrThrow<string>(
          'JWT_ACCESS_SECRET',
        ),
    });
  }

  // ==========================================
  // VALIDATE ACCESS TOKEN
  // ==========================================

  async validate(
    payload: JwtPayload,
  ): Promise<AuthenticatedUser> {
    if (
      !payload ||
      typeof payload.sub !== 'string' ||
      typeof payload.sid !== 'string'
    ) {
      throw new UnauthorizedException(
        'Invalid access token',
      );
    }

    const now = new Date();

    // Verify session and account on every request.

    const [session] = await this.connection.db
      .select({
        userId: users.id,

        sessionId: authSessions.id,

        role: users.role,
      })
      .from(authSessions)
      .innerJoin(
        users,
        eq(
          authSessions.userId,
          users.id,
        ),
      )
      .where(
        and(
          eq(
            authSessions.id,
            payload.sid,
          ),

          eq(
            authSessions.userId,
            payload.sub,
          ),

          isNull(
            authSessions.revokedAt,
          ),

          gt(
            authSessions.expiresAt,
            now,
          ),

          eq(
            users.isActive,
            true,
          ),
        ),
      )
      .limit(1);

    if (!session) {
      throw new UnauthorizedException(
        'Session is invalid or expired',
      );
    }

    return {
      userId: session.userId,

      sessionId: session.sessionId,

      role: session.role,
    };
  }
}
