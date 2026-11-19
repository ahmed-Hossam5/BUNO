
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  and,
  count,
  desc,
  eq,
  gte,
  lte,
} from 'drizzle-orm';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import type { databaseProvider } from '../../database/database.provider.js';

import {
  auditLogs,
  auditActionEnum,
} from '../../database/schema/audit-logs.schema.js';

import { users } from '../../database/schema/users.schema.js';

import type { FindAuditLogsQueryDto } from './dto/find-audit-logs-query.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

// ==========================================
// TYPES
// ==========================================

export type AuditAction =
  (typeof auditActionEnum.enumValues)[number];

// Either the main database handle or a transaction.
// Passing a transaction makes the audit row part of the
// same atomic unit as the business change.
export type AuditExecutor = Pick<
  DatabaseConnection['db'],
  'insert'
>;

export interface AuditEntry {
  userId?: string | null;
  action: AuditAction;
  entityType: string;
  entityId?: string | null;
  oldValues?: unknown;
  newValues?: unknown;
  ipAddress?: string | null;
}

// ==========================================
// SANITIZATION
// ==========================================
//
// Audit rows must never become a second copy of secrets.

const SENSITIVE_KEY =
  /password|passwd|secret|token|authorization|api[-_]?key|hash|credential/i;

const REDACTED = '[REDACTED]';
const MAX_DEPTH = 6;

export function sanitizeAuditValue(
  value: unknown,
  depth = 0,
): unknown {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value === 'bigint') {
    return value.toString();
  }

  if (
    typeof value === 'function' ||
    typeof value === 'symbol'
  ) {
    return null;
  }

  if (typeof value !== 'object') {
    return value;
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (depth >= MAX_DEPTH) {
    return '[TRUNCATED]';
  }

  if (Array.isArray(value)) {
    return value.map((item) =>
      sanitizeAuditValue(item, depth + 1),
    );
  }

  const result: Record<string, unknown> = {};

  for (const [key, item] of Object.entries(value)) {
    result[key] = SENSITIVE_KEY.test(key)
      ? REDACTED
      : sanitizeAuditValue(item, depth + 1);
  }

  return result;
}

// ==========================================
// AUDIT LOGS SERVICE
// ==========================================

@Injectable()
export class AuditLogsService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {}

  // ==========================================
  // RECORD AN AUDIT ENTRY
  // ==========================================
  //
  // Pass the active transaction as `executor` so the log
  // is committed (or rolled back) together with the change.

  async record(
    entry: AuditEntry,
    executor: AuditExecutor = this.connection.db,
  ): Promise<void> {
    await executor.insert(auditLogs).values({
      userId: entry.userId ?? null,

      action: entry.action,

      entityType: entry.entityType.slice(0, 100),

      entityId: entry.entityId
        ? entry.entityId.slice(0, 100)
        : null,

      oldValues:
        entry.oldValues === undefined
          ? null
          : sanitizeAuditValue(entry.oldValues),

      newValues:
        entry.newValues === undefined
          ? null
          : sanitizeAuditValue(entry.newValues),

      ipAddress: entry.ipAddress ?? null,
    });
  }

  // Bulk version (used by system jobs).
  async recordMany(
    entries: AuditEntry[],
    executor: AuditExecutor = this.connection.db,
  ): Promise<void> {
    if (entries.length === 0) {
      return;
    }

    await executor.insert(auditLogs).values(
      entries.map((entry) => ({
        userId: entry.userId ?? null,
        action: entry.action,
        entityType: entry.entityType.slice(0, 100),
        entityId: entry.entityId
          ? entry.entityId.slice(0, 100)
          : null,
        oldValues:
          entry.oldValues === undefined
            ? null
            : sanitizeAuditValue(entry.oldValues),
        newValues:
          entry.newValues === undefined
            ? null
            : sanitizeAuditValue(entry.newValues),
        ipAddress: entry.ipAddress ?? null,
      })),
    );
  }

  // ==========================================
  // LIST AUDIT LOGS (paginated + filtered)
  // ==========================================

  async findAll(query: FindAuditLogsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    const from = query.from
      ? new Date(query.from)
      : undefined;

    const to = query.to
      ? new Date(query.to)
      : undefined;

    if (from && to && from > to) {
      throw new BadRequestException(
        '"from" must not be later than "to"',
      );
    }

    const whereCondition = and(
      query.userId
        ? eq(auditLogs.userId, query.userId)
        : undefined,

      query.action
        ? eq(auditLogs.action, query.action)
        : undefined,

      query.entityType
        ? eq(auditLogs.entityType, query.entityType)
        : undefined,

      query.entityId
        ? eq(auditLogs.entityId, query.entityId)
        : undefined,

      from ? gte(auditLogs.createdAt, from) : undefined,

      to ? lte(auditLogs.createdAt, to) : undefined,
    );

    const [data, countResult] = await Promise.all([
      this.connection.db
        .select({
          log: auditLogs,
          actor: {
            fullName: users.fullName,
            email: users.email,
            role: users.role,
          },
        })
        .from(auditLogs)
        .leftJoin(users, eq(auditLogs.userId, users.id))
        .where(whereCondition)
        .orderBy(
          desc(auditLogs.createdAt),
          desc(auditLogs.id),
        )
        .limit(limit)
        .offset(offset),

      this.connection.db
        .select({ total: count() })
        .from(auditLogs)
        .where(whereCondition),
    ]);

    const total = countResult[0]?.total ?? 0;
    const totalPages = Math.ceil(total / limit);

    return {
      data: data.map(({ log, actor }) => ({
        ...log,
        actor: log.userId ? actor : null,
      })),

      meta: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  // ==========================================
  // GET ONE AUDIT LOG
  // ==========================================

  async findOne(id: string) {
    const [result] = await this.connection.db
      .select({
        log: auditLogs,
        actor: {
          fullName: users.fullName,
          email: users.email,
          role: users.role,
        },
      })
      .from(auditLogs)
      .leftJoin(users, eq(auditLogs.userId, users.id))
      .where(eq(auditLogs.id, id))
      .limit(1);

    if (!result) {
      throw new NotFoundException('Audit log not found');
    }

    return {
      ...result.log,
      actor: result.log.userId ? result.actor : null,
    };
  }
}
