
import {
  createParamDecorator,
  ExecutionContext,
} from '@nestjs/common';

import { isIP } from 'node:net';

interface RequestWithIp {
  ip?: string;
}

// Returns the caller IP address or null.
// Strips the IPv4-mapped IPv6 prefix (::ffff:1.2.3.4)
// and never returns a value that Postgres `inet` rejects.
//
// Behind a reverse proxy / load balancer, enable
// `app.set('trust proxy', ...)` so req.ip is the real client.
export function normalizeIp(
  raw: string | undefined | null,
): string | null {
  if (!raw) {
    return null;
  }

  const value = raw.startsWith('::ffff:')
    ? raw.slice(7)
    : raw;

  return isIP(value) !== 0 ? value : null;
}

export const ClientIp = createParamDecorator(
  (
    _data: unknown,
    context: ExecutionContext,
  ): string | null => {
    const request = context
      .switchToHttp()
      .getRequest<RequestWithIp>();

    return normalizeIp(request.ip);
  },
);
