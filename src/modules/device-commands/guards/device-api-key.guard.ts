
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';

import { ConfigService } from '@nestjs/config';

import { createHash, timingSafeEqual } from 'node:crypto';

interface RequestWithHeaders {
  headers: Record<string, string | string[] | undefined>;
}

const digest = (value: string): Buffer =>
  createHash('sha256').update(value).digest();

// ==========================================
// DEVICE API KEY GUARD
// ==========================================
//
// Station firmware authenticates with a shared secret sent in
// the `x-device-key` header and configured as DEVICE_API_KEY.
// Fail-closed: if DEVICE_API_KEY is not configured every
// device request is rejected.
//
// NOTE: this is one key for the whole fleet. Per-station
// credentials (stored hashed in the database) are the natural
// next hardening step.

@Injectable()
export class DeviceApiKeyGuard implements CanActivate {
  private readonly logger = new Logger(
    DeviceApiKeyGuard.name,
  );

  private warned = false;

  constructor(
    @Inject(ConfigService)
    private readonly configService: ConfigService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const expected =
      this.configService.get<string>('DEVICE_API_KEY');

    if (!expected) {
      if (!this.warned) {
        this.warned = true;
        this.logger.error(
          'DEVICE_API_KEY is not configured: all device requests are rejected',
        );
      }

      throw new UnauthorizedException(
        'Invalid device credentials',
      );
    }

    const request = context
      .switchToHttp()
      .getRequest<RequestWithHeaders>();

    const header = request.headers['x-device-key'];

    const provided =
      typeof header === 'string' ? header : undefined;

    if (
      !provided ||
      !timingSafeEqual(digest(provided), digest(expected))
    ) {
      throw new UnauthorizedException(
        'Invalid device credentials',
      );
    }

    return true;
  }
}
