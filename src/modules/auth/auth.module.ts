
import { Module } from '@nestjs/common';

import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';

import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';

import { JwtStrategy } from './strategies/jwt.strategy.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';

@Module({
  imports: [
    // Rate Limiting Configuration
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 100,
      },
    ]),

    // Passport Configuration
    PassportModule.register({
      defaultStrategy: 'jwt',
    }),

    // JWT Configuration
    JwtModule.registerAsync({
      inject: [ConfigService],

      useFactory: (configService: ConfigService) => ({
        secret: configService.getOrThrow<string>(
          'JWT_ACCESS_SECRET',
        ),

        signOptions: {
          expiresIn: 900,
          algorithm: 'HS256',
        },
      }),
    }),
  ],

  controllers: [
    AuthController,
  ],

  providers: [
    AuthService,
    JwtStrategy,
    JwtAuthGuard,
  ],

  exports: [
    AuthService,
    JwtAuthGuard,
  ],
})
export class AuthModule {}
