import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  and,
  asc,
  count,
  desc,
  eq,
  gt,
  inArray,
  isNull,
  lte,
  or,
  type SQL,
} from 'drizzle-orm';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import { isUniqueViolation } from '../../database/database-errors.js';
import type { databaseProvider } from '../../database/database.provider.js';

import {
  deviceCommands,
  deviceCommandStatusEnum,
  deviceCommandTypeEnum,
} from '../../database/schema/device-commands.schema.js';

import { stations } from '../../database/schema/stations.schema.js';
import { ports } from '../../database/schema/ports.schema.js';
import { powerBanks } from '../../database/schema/power-banks.schema.js';

import { AuditLogsService } from '../audit-logs/audit-logs.service.js';

import type { CreateDeviceCommandDto } from './dto/create-device-command.dto.js';
import type { FindDeviceCommandsQueryDto } from './dto/find-device-commands-query.dto.js';
import type { ReportCommandResultDto } from './dto/report-command-result.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

type Tx = Parameters<Parameters<DatabaseConnection['db']['transaction']>[0]>[0];

export type DeviceCommandStatus =
  (typeof deviceCommandStatusEnum.enumValues)[number];

export type DeviceCommandType =
  (typeof deviceCommandTypeEnum.enumValues)[number];

export interface CommandActor {
  userId: string | null;
  ip: string | null;
}

// ==========================================
// STATE MACHINE
// ==========================================
//
//  PENDING ──► SENT ──► ACKNOWLEDGED ──► SUCCEEDED
//     │          │            │       └─► FAILED
//     │          └────────────┴─────────► TIMED_OUT
//     └──► CANCELLED (only while still PENDING)
//
// A device may report SUCCEEDED/FAILED straight from SENT
// (skipping ACKNOWLEDGED), and may report a late result for a
// TIMED_OUT command because the physical outcome is the truth.

const ACTIVE_STATUSES: DeviceCommandStatus[] = [
  'PENDING',
  'SENT',
  'ACKNOWLEDGED',
];

const DEFAULT_TTL_SECONDS: Record<DeviceCommandType, number> = {
  RELEASE_POWER_BANK: 60,
  STOP_CHARGING: 300,
  RESTART_STATION: 300,
  LOCK_PORT: 300,
  UNLOCK_PORT: 300,
};

const MAX_PAYLOAD_BYTES = 4096;
const POLL_BATCH_SIZE = 20;

@Injectable()
export class DeviceCommandsService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,

    @Inject(AuditLogsService)
    private readonly auditLogs: AuditLogsService,
  ) {}

  // ==========================================
  // CREATE COMMAND
  // Used by the staff API and, later, by the rentals flow
  // ==========================================

  async create(dto: CreateDeviceCommandDto, actor: CommandActor) {
    if (
      dto.payload !== undefined &&
      Buffer.byteLength(JSON.stringify(dto.payload)) > MAX_PAYLOAD_BYTES
    ) {
      throw new BadRequestException(
        `Payload must not exceed ${MAX_PAYLOAD_BYTES} bytes`,
      );
    }

    const isStationCommand = dto.commandType === 'RESTART_STATION';

    if (isStationCommand && dto.portId) {
      throw new BadRequestException('RESTART_STATION must not specify a port');
    }

    if (!isStationCommand && !dto.portId) {
      throw new BadRequestException(`${dto.commandType} requires a portId`);
    }

    try {
      return await this.connection.db.transaction(async (tx) => {
        // 1. Lock the station (serializes commands per station)

        const [station] = await tx
          .select()
          .from(stations)
          .where(eq(stations.id, dto.stationId))
          .limit(1)
          .for('no key update');

        if (!station) {
          throw new NotFoundException('Station not found');
        }

        if (station.status === 'OFFLINE') {
          throw new ConflictException(
            'Station is offline and cannot receive commands',
          );
        }

        if (
          dto.commandType === 'RELEASE_POWER_BANK' &&
          station.status !== 'ONLINE'
        ) {
          throw new ConflictException(
            'Station must be ONLINE to release a Power Bank',
          );
        }

        // 2. Resolve and lock the port (must belong to the station)

        let portId: string | null = null;
        let powerBankId: string | null = null;

        if (!isStationCommand) {
          const [port] = await tx
            .select()
            .from(ports)
            .where(
              and(
                eq(ports.id, dto.portId as string),
                eq(ports.stationId, dto.stationId),
              ),
            )
            .limit(1)
            .for('no key update');

          if (!port) {
            throw new NotFoundException('Port not found in this station');
          }

          portId = port.id;

          const [bank] = await tx
            .select({
              id: powerBanks.id,
              status: powerBanks.status,
            })
            .from(powerBanks)
            .where(eq(powerBanks.currentPortId, port.id))
            .limit(1);

          if (dto.commandType === 'RELEASE_POWER_BANK') {
            if (port.status !== 'OCCUPIED' || !bank) {
              throw new ConflictException(
                'Port does not contain a Power Bank to release',
              );
            }

            if (bank.status !== 'AVAILABLE' && bank.status !== 'RESERVED') {
              throw new ConflictException(
                `Power Bank cannot be released while ${bank.status}`,
              );
            }
          }

          powerBankId = bank?.id ?? null;
        }

        // 3. Time out stale commands so they cannot block new ones

        await this.expireStale(tx, eq(deviceCommands.stationId, dto.stationId));

        // 4. One active command per port,
        //    one active RESTART_STATION per station

        const [activeCommand] = await tx
          .select({ id: deviceCommands.id })
          .from(deviceCommands)
          .where(
            and(
              eq(deviceCommands.stationId, dto.stationId),
              inArray(deviceCommands.status, ACTIVE_STATUSES),
              isStationCommand
                ? eq(deviceCommands.commandType, 'RESTART_STATION')
                : eq(deviceCommands.portId, portId as string),
            ),
          )
          .limit(1);

        if (activeCommand) {
          throw new ConflictException(
            isStationCommand
              ? 'A restart command is already active for this station'
              : 'Another command is already active for this port',
          );
        }

        // 5. Insert command

        const ttlSeconds =
          dto.ttlSeconds ?? DEFAULT_TTL_SECONDS[dto.commandType];

        const expiresAt = new Date(Date.now() + ttlSeconds * 1000);

        const [command] = await tx
          .insert(deviceCommands)
          .values({
            stationId: dto.stationId,
            portId,
            powerBankId,
            requestedBy: actor.userId,
            commandType: dto.commandType,
            payload: dto.payload ?? null,
            expiresAt,
          })
          .returning();

        // 6. Audit (same transaction)

        await this.auditLogs.record(
          {
            userId: actor.userId,
            action: 'COMMAND',
            entityType: 'device_command',
            entityId: command.id,
            newValues: {
              commandId: command.commandId,
              commandType: command.commandType,
              stationId: command.stationId,
              portId: command.portId,
              powerBankId: command.powerBankId,
              status: command.status,
              expiresAt: command.expiresAt,
            },
            ipAddress: actor.ip,
          },
          tx,
        );

        return command;
      });
    } catch (error) {
      // Safety net: the partial unique indexes
      // (device_commands_active_*_unique) enforce the rule
      // even if two requests race past the checks above.
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          isStationCommand
            ? 'A restart command is already active for this station'
            : 'Another command is already active for this port',
        );
      }

      throw error;
    }
  }

  // ==========================================
  // LIST COMMANDS
  // ==========================================

  async findAll(query: FindDeviceCommandsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    const whereCondition = and(
      query.stationId
        ? eq(deviceCommands.stationId, query.stationId)
        : undefined,

      query.portId ? eq(deviceCommands.portId, query.portId) : undefined,

      query.status ? eq(deviceCommands.status, query.status) : undefined,

      query.commandType
        ? eq(deviceCommands.commandType, query.commandType)
        : undefined,
    );

    const [data, countResult] = await Promise.all([
      this.connection.db
        .select()
        .from(deviceCommands)
        .where(whereCondition)
        .orderBy(desc(deviceCommands.createdAt), desc(deviceCommands.id))
        .limit(limit)
        .offset(offset),

      this.connection.db
        .select({ total: count() })
        .from(deviceCommands)
        .where(whereCondition),
    ]);

    const total = countResult[0]?.total ?? 0;
    const totalPages = Math.ceil(total / limit);

    return {
      data,
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
  // GET ONE COMMAND
  // ==========================================

  async findOne(id: string) {
    const [command] = await this.connection.db
      .select()
      .from(deviceCommands)
      .where(eq(deviceCommands.id, id))
      .limit(1);

    if (!command) {
      throw new NotFoundException('Device command not found');
    }

    return command;
  }

  // ==========================================
  // CANCEL COMMAND (only while PENDING)
  // ==========================================

  async cancel(id: string, actor: CommandActor) {
    return this.connection.db.transaction(async (tx) => {
      const [command] = await tx
        .select()
        .from(deviceCommands)
        .where(eq(deviceCommands.id, id))
        .limit(1)
        .for('update');

      if (!command) {
        throw new NotFoundException('Device command not found');
      }

      // Idempotent
      if (command.status === 'CANCELLED') {
        return command;
      }

      if (command.status !== 'PENDING') {
        throw new ConflictException(
          `Only PENDING commands can be cancelled (current status: ${command.status})`,
        );
      }

      const [updated] = await tx
        .update(deviceCommands)
        .set({
          status: 'CANCELLED',
          completedAt: new Date(),
        })
        .where(eq(deviceCommands.id, id))
        .returning();

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'device_command',
          entityId: id,
          oldValues: { status: command.status },
          newValues: { status: updated.status },
          ipAddress: actor.ip,
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // DEVICE SIDE: POLL
  // Claims PENDING commands (-> SENT) and re-delivers
  // SENT commands that were never acknowledged.
  // The device de-duplicates by commandId.
  // ==========================================

  async poll(stationId: string) {
    return this.connection.db.transaction(async (tx) => {
      const [station] = await tx
        .select({ id: stations.id })
        .from(stations)
        .where(eq(stations.id, stationId))
        .limit(1);

      if (!station) {
        throw new NotFoundException('Station not found');
      }

      await this.expireStale(tx, eq(deviceCommands.stationId, stationId));

      const now = new Date();

      // Claim PENDING commands (safe under concurrent polls)

      const claimable = await tx
        .select({ id: deviceCommands.id })
        .from(deviceCommands)
        .where(
          and(
            eq(deviceCommands.stationId, stationId),
            eq(deviceCommands.status, 'PENDING'),
            or(
              isNull(deviceCommands.expiresAt),
              gt(deviceCommands.expiresAt, now),
            ),
          ),
        )
        .orderBy(asc(deviceCommands.createdAt))
        .limit(POLL_BATCH_SIZE)
        .for('update', { skipLocked: true });

      const claimedIds = claimable.map((row) => row.id);

      if (claimedIds.length > 0) {
        await tx
          .update(deviceCommands)
          .set({ status: 'SENT', sentAt: now })
          .where(inArray(deviceCommands.id, claimedIds));

        await this.auditLogs.recordMany(
          claimedIds.map((id) => ({
            userId: null,
            action: 'STATUS_CHANGE' as const,
            entityType: 'device_command',
            entityId: id,
            oldValues: { status: 'PENDING' },
            newValues: { status: 'SENT' },
          })),
          tx,
        );
      }

      // Everything the device should currently act on

      const commands = await tx
        .select({
          commandId: deviceCommands.commandId,
          commandType: deviceCommands.commandType,
          portId: deviceCommands.portId,
          portNumber: ports.portNumber,
          powerBankId: deviceCommands.powerBankId,
          deviceIdentifier: powerBanks.deviceIdentifier,
          payload: deviceCommands.payload,
          createdAt: deviceCommands.createdAt,
          expiresAt: deviceCommands.expiresAt,
        })
        .from(deviceCommands)
        .leftJoin(ports, eq(deviceCommands.portId, ports.id))
        .leftJoin(powerBanks, eq(deviceCommands.powerBankId, powerBanks.id))
        .where(
          and(
            eq(deviceCommands.stationId, stationId),
            eq(deviceCommands.status, 'SENT'),
            or(
              isNull(deviceCommands.expiresAt),
              gt(deviceCommands.expiresAt, now),
            ),
          ),
        )
        .orderBy(asc(deviceCommands.createdAt));

      return { commands };
    });
  }

  // ==========================================
  // DEVICE SIDE: ACKNOWLEDGE
  // ==========================================

  async acknowledge(stationId: string, commandId: string) {
    return this.connection.db.transaction(async (tx) => {
      const command = await this.lockCommandForStation(
        tx,
        stationId,
        commandId,
      );

      // Idempotent
      if (command.status === 'ACKNOWLEDGED') {
        return command;
      }

      if (command.status === 'PENDING') {
        throw new ConflictException(
          'Command has not been delivered to the device yet',
        );
      }

      if (command.status !== 'SENT') {
        throw new ConflictException(
          `Command cannot be acknowledged (current status: ${command.status})`,
        );
      }

      if (command.expiresAt && command.expiresAt.getTime() <= Date.now()) {
        throw new ConflictException('Command has expired');
      }

      const [updated] = await tx
        .update(deviceCommands)
        .set({
          status: 'ACKNOWLEDGED',
          acknowledgedAt: new Date(),
        })
        .where(eq(deviceCommands.id, command.id))
        .returning();

      await this.auditLogs.record(
        {
          userId: null,
          action: 'STATUS_CHANGE',
          entityType: 'device_command',
          entityId: command.id,
          oldValues: { status: command.status },
          newValues: { status: updated.status },
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // DEVICE SIDE: REPORT RESULT
  // ==========================================

  async reportResult(
    stationId: string,
    commandId: string,
    dto: ReportCommandResultDto,
  ) {
    const outcome: DeviceCommandStatus = dto.success ? 'SUCCEEDED' : 'FAILED';

    if (
      dto.response !== undefined &&
      Buffer.byteLength(JSON.stringify(dto.response)) > MAX_PAYLOAD_BYTES
    ) {
      throw new BadRequestException(
        `Response must not exceed ${MAX_PAYLOAD_BYTES} bytes`,
      );
    }

    return this.connection.db.transaction(async (tx) => {
      const command = await this.lockCommandForStation(
        tx,
        stationId,
        commandId,
      );

      // Idempotent: same outcome reported twice
      if (command.status === 'SUCCEEDED' || command.status === 'FAILED') {
        if (command.status === outcome) {
          return command;
        }

        throw new ConflictException(
          `Command already finished as ${command.status}`,
        );
      }

      if (command.status === 'PENDING') {
        throw new ConflictException(
          'Command has not been delivered to the device yet',
        );
      }

      if (command.status === 'CANCELLED') {
        throw new ConflictException('Command was cancelled');
      }

      const isLateResult = command.status === 'TIMED_OUT';
      const now = new Date();

      const [updated] = await tx
        .update(deviceCommands)
        .set({
          status: outcome,
          response: dto.response ?? null,
          acknowledgedAt: command.acknowledgedAt ?? now,
          completedAt: now,
        })
        .where(eq(deviceCommands.id, command.id))
        .returning();

      await this.auditLogs.record(
        {
          userId: null,
          action: 'STATUS_CHANGE',
          entityType: 'device_command',
          entityId: command.id,
          oldValues: { status: command.status },
          newValues: {
            status: updated.status,
            ...(isLateResult && { lateResult: true }),
          },
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // SWEEPER: TIME OUT EXPIRED COMMANDS
  // ==========================================

  async expireStaleCommands(): Promise<number> {
    return this.connection.db.transaction(async (tx) => {
      const expired = await this.expireStale(tx);
      return expired.length;
    });
  }

  // ==========================================
  // INTERNAL HELPERS
  // ==========================================

  private async lockCommandForStation(
    tx: Tx,
    stationId: string,
    commandId: string,
  ) {
    const [command] = await tx
      .select()
      .from(deviceCommands)
      .where(
        and(
          eq(deviceCommands.commandId, commandId),
          eq(deviceCommands.stationId, stationId),
        ),
      )
      .limit(1)
      .for('update');

    if (!command) {
      throw new NotFoundException('Device command not found for this station');
    }

    return command;
  }

  // Marks active commands whose TTL elapsed as TIMED_OUT
  // and audits each transition. Skips rows locked by other
  // transactions so it never blocks live traffic.
  private async expireStale(tx: Tx, scope?: SQL) {
    const now = new Date();

    const stale = await tx
      .select({
        id: deviceCommands.id,
        status: deviceCommands.status,
      })
      .from(deviceCommands)
      .where(
        and(
          inArray(deviceCommands.status, ACTIVE_STATUSES),
          lte(deviceCommands.expiresAt, now),
          scope,
        ),
      )
      .for('update', { skipLocked: true });

    if (stale.length === 0) {
      return [];
    }

    await tx
      .update(deviceCommands)
      .set({ status: 'TIMED_OUT', completedAt: now })
      .where(
        inArray(
          deviceCommands.id,
          stale.map((row) => row.id),
        ),
      );

    await this.auditLogs.recordMany(
      stale.map((row) => ({
        userId: null,
        action: 'STATUS_CHANGE' as const,
        entityType: 'device_command',
        entityId: row.id,
        oldValues: { status: row.status },
        newValues: {
          status: 'TIMED_OUT',
          reason: 'EXPIRED',
        },
      })),
      tx,
    );

    return stale;
  }
}
