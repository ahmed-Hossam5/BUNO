
import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';

import {
  Throttle,
  ThrottlerGuard,
} from '@nestjs/throttler';

import { AuthService } from './auth.service.js';

import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';

import { CurrentUser } from './decorators/current-user.decorator.js';

import { JwtAuthGuard } from './guards/jwt-auth.guard.js';

import type {
  AuthenticatedUser,
} from './strategies/jwt.strategy.js';

// ==========================================
// AUTH CONTROLLER
// ==========================================

@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(
    private readonly authService: AuthService,
  ) {}

  // ==========================================
  // REGISTER
  // 5 Requests / 60 Seconds
  // ==========================================

  @Throttle({
    default: {
      limit: 5,
      ttl: 60_000,
    },
  })
  @Post('register')
  register(
    @Body() dto: RegisterDto,
  ) {
    return this.authService.register(dto);
  }

  // ==========================================
  // LOGIN
  // 5 Requests / 60 Seconds
  // ==========================================

  @Throttle({
    default: {
      limit: 5,
      ttl: 60_000,
    },
  })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(
    @Body() dto: LoginDto,
  ) {
    return this.authService.login(dto);
  }

  // ==========================================
  // REFRESH TOKEN
  // 10 Requests / 60 Seconds
  // ==========================================

  @Throttle({
    default: {
      limit: 10,
      ttl: 60_000,
    },
  })
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(
    @Body() dto: RefreshTokenDto,
  ) {
    return this.authService.refresh(dto);
  }

  // ==========================================
  // LOGOUT
  // Default: 100 Requests / 60 Seconds
  // Requires Authentication
  // ==========================================

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  logout(
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.authService.logout(
      user.userId,
      user.sessionId,
    );
  }

  // ==========================================
  // CURRENT USER
  // Default: 100 Requests / 60 Seconds
  // Requires Authentication
  // ==========================================

  @Get('me')
  @UseGuards(JwtAuthGuard)
  getMe(
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.authService.getMe(
      user.userId,
    );
  }
}
