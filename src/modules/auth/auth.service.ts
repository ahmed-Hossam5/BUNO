
import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import { JwtService } from '@nestjs/jwt';

import {
  and,
  eq,
  gt,
  isNull,
} from 'drizzle-orm';

import {
  createHash,
  randomBytes,
  randomUUID,
} from 'node:crypto';

import {
  compare,
  hash,
} from 'bcryptjs';

import {
  users,
} from '../../database/schema/users.schema.js';

import {
  authSessions,
} from '../../database/schema/auth-sessions.schema.js';

import {
  DATABASE_CONNECTION,
} from '../../database/database.constants.js';

import type {
  databaseProvider,
} from '../../database/database.provider.js';

import type {
  RegisterDto,
} from './dto/register.dto.js';

import type {
  LoginDto,
} from './dto/login.dto.js';

import type {
  RefreshTokenDto,
} from './dto/refresh-token.dto.js';

// ==========================================
// DATABASE TYPE
// ==========================================

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

// ==========================================
// AUTH USER TYPE
// ==========================================

type AuthUser = Pick<
  typeof users.$inferSelect,
  'id' | 'fullName' | 'email' | 'phone' | 'role'
>;

// ==========================================
// AUTH SERVICE
// ==========================================

@Injectable()
export class AuthService {
  private readonly PASSWORD_ROUNDS = 12;

  private readonly ACCESS_TOKEN_EXPIRES_IN = 900;

  private readonly REFRESH_TOKEN_TTL =
    30 * 24 * 60 * 60 * 1000;

  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,

    private readonly jwtService: JwtService,
  ) {}

  // ==========================================
  // 1. REGISTER
  // ==========================================

  async register(dto: RegisterDto) {
    const fullName = dto.fullName.trim();

    const email = dto.email.trim().toLowerCase();

    const phone = dto.phone?.trim() || null;

    if (!fullName) {
      throw new BadRequestException(
        'Full name cannot be empty',
      );
    }

    // bcrypt supports passwords up to 72 bytes.

    if (
      Buffer.byteLength(dto.password, 'utf8') > 72
    ) {
      throw new BadRequestException(
        'Password must not exceed 72 UTF-8 bytes',
      );
    }

    // Hash password before storing it.

    const passwordHash = await hash(
      dto.password,
      this.PASSWORD_ROUNDS,
    );

    let createdUser: AuthUser;

    try {
      const [result] = await this.connection.db
        .insert(users)
        .values({
          fullName,
          email,
          passwordHash,
          phone,

          // Role is not accepted from the client.
          // Database default is CUSTOMER.
        })
        .returning({
          id: users.id,
          fullName: users.fullName,
          email: users.email,
          phone: users.phone,
          role: users.role,
        });

      if (!result) {
        throw new Error('Failed to create user');
      }

      createdUser = result;

    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw new ConflictException(
          'Email or phone number already registered',
        );
      }

      throw error;
    }

    return this.createSession(createdUser);
  }

  // ==========================================
  // 2. LOGIN
  // ==========================================

  async login(dto: LoginDto) {
    if (
      Buffer.byteLength(dto.password, 'utf8') > 72
    ) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const email = dto.email.trim().toLowerCase();

    const [user] = await this.connection.db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        phone: users.phone,
        role: users.role,
        passwordHash: users.passwordHash,
        isActive: users.isActive,
      })
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (
      !user ||
      !user.isActive ||
      !(await compare(
        dto.password,
        user.passwordHash,
      ))
    ) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const authUser: AuthUser = {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
    };

    return this.createSession(authUser);
  }

  // ==========================================
  // 3. CREATE SESSION
  // ==========================================

  private async createSession(
    user: AuthUser,
  ) {
    const sessionId = randomUUID();

    // Generate secure random refresh token.

    const refreshToken = randomBytes(48)
      .toString('base64url');

    // Store only SHA-256 hash in database.

    const refreshTokenHash =
      this.hashRefreshToken(refreshToken);

    const now = new Date();

    const expiresAt = new Date(
      now.getTime() + this.REFRESH_TOKEN_TTL,
    );

    // Generate access token.

    const accessToken =
      await this.jwtService.signAsync({
        sub: user.id,
        sid: sessionId,
      });

    // Persist session.

    await this.connection.db
      .insert(authSessions)
      .values({
        id: sessionId,
        userId: user.id,
        refreshTokenHash,
        expiresAt,
      });

    return {
      user,

      accessToken,

      refreshToken,

      tokenType: 'Bearer',

      expiresIn: this.ACCESS_TOKEN_EXPIRES_IN,

      refreshTokenExpiresAt: expiresAt,
    };
  }

  // ==========================================
  // 4. REFRESH TOKEN ROTATION
  // ==========================================

  async refresh(
    dto: RefreshTokenDto,
  ) {
    const oldHash = this.hashRefreshToken(
      dto.refreshToken,
    );

    const now = new Date();

    // Find valid session and its owner.

    const [record] = await this.connection.db
      .select({
        sessionId: authSessions.id,

        userId: users.id,

        fullName: users.fullName,

        email: users.email,

        phone: users.phone,

        role: users.role,
      })
      .from(authSessions)
      .innerJoin(
        users,
        eq(authSessions.userId, users.id),
      )
      .where(
        and(
          eq(
            authSessions.refreshTokenHash,
            oldHash,
          ),

          isNull(authSessions.revokedAt),

          gt(authSessions.expiresAt, now),

          eq(users.isActive, true),
        ),
      )
      .limit(1);

    if (!record) {
      throw new UnauthorizedException(
        'Invalid or expired refresh token',
      );
    }

    // Generate replacement refresh token.

    const newRefreshToken = randomBytes(48)
      .toString('base64url');

    const newHash = this.hashRefreshToken(
      newRefreshToken,
    );

    const newExpiresAt = new Date(
      now.getTime() + this.REFRESH_TOKEN_TTL,
    );

    // Generate access token before changing
    // the existing database session.

    const accessToken =
      await this.jwtService.signAsync({
        sub: record.userId,
        sid: record.sessionId,
      });

    // Atomic token rotation.
    // Only one concurrent request can succeed.

    const [updatedSession] =
      await this.connection.db
        .update(authSessions)
        .set({
          refreshTokenHash: newHash,

          expiresAt: newExpiresAt,

          lastUsedAt: now,

          updatedAt: now,
        })
        .where(
          and(
            eq(
              authSessions.id,
              record.sessionId,
            ),

            eq(
              authSessions.refreshTokenHash,
              oldHash,
            ),

            isNull(authSessions.revokedAt),

            gt(authSessions.expiresAt, now),
          ),
        )
        .returning({
          id: authSessions.id,
        });

    if (!updatedSession) {
      throw new UnauthorizedException(
        'Refresh token has already been used',
      );
    }

    return {
      user: {
        id: record.userId,
        fullName: record.fullName,
        email: record.email,
        phone: record.phone,
        role: record.role,
      },

      accessToken,

      refreshToken: newRefreshToken,

      tokenType: 'Bearer',

      expiresIn: this.ACCESS_TOKEN_EXPIRES_IN,

      refreshTokenExpiresAt: newExpiresAt,
    };
  }

  // ==========================================
  // 5. LOGOUT
  // ==========================================

  async logout(
    userId: string,
    sessionId: string,
  ) {
    const now = new Date();

    await this.connection.db
      .update(authSessions)
      .set({
        revokedAt: now,

        updatedAt: now,
      })
      .where(
        and(
          eq(authSessions.id, sessionId),

          eq(authSessions.userId, userId),

          isNull(authSessions.revokedAt),
        ),
      );

    return {
      message: 'Logged out successfully',
    };
  }

  // ==========================================
  // 6. GET CURRENT USER
  // ==========================================

  async getMe(userId: string) {
    const [user] = await this.connection.db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        phone: users.phone,
        role: users.role,
        createdAt: users.createdAt,
      })
      .from(users)
      .where(
        and(
          eq(users.id, userId),

          eq(users.isActive, true),
        ),
      )
      .limit(1);

    if (!user) {
      throw new UnauthorizedException(
        'User is not available',
      );
    }

    return user;
  }

  // ==========================================
  // 7. HASH REFRESH TOKEN
  // ==========================================

  private hashRefreshToken(
    token: string,
  ): string {
    return createHash('sha256')
      .update(token)
      .digest('hex');
  }

  // ==========================================
  // 8. UNIQUE CONSTRAINT CHECK
  // ==========================================

  private isUniqueViolation(
    error: unknown,
  ): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === '23505'
    );
  }
}
