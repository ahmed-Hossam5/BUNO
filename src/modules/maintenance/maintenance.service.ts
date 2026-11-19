
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  and,
  count,
  desc,
  eq,
  gt,
  inArray,
  isNull,
  or,
} from 'drizzle-orm';

import { alias } from 'drizzle-orm/pg-core';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import type { databaseProvider } from '../../database/database.provider.js';
import { isUniqueViolation } from '../../database/database-errors.js';

import {
  maintenanceRecords,
} from '../../database/schema/maintenance.schema.js';

import { stations } from '../../database/schema/stations.schema.js';
import { ports } from '../../database/schema/ports.schema.js';
import { powerBanks } from '../../database/schema/power-banks.schema.js';
import { powerBankMovements } from '../../database/schema/power-bank-movements.schema.js';
import { rentals } from '../../database/schema/rentals.schema.js';
import { transferMissionItems } from '../../database/schema/transfer-mission-items.schema.js';
import { deviceCommands } from '../../database/schema/device-commands.schema.js';
import { users } from '../../database/schema/users.schema.js';

import { AuditLogsService } from '../audit-logs/audit-logs.service.js';
import type { UserRole } from '../auth/decorators/roles.decorator.js';

import type { CreateMaintenanceDto } from './dto/create-maintenance.dto.js';
import type { CompleteMaintenanceDto } from './dto/complete-maintenance.dto.js';
import type { CancelMaintenanceDto } from './dto/cancel-maintenance.dto.js';
import type { AssignMaintenanceDto } from './dto/assign-maintenance.dto.js';
import type { FindMaintenanceQueryDto } from './dto/find-maintenance-query.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

type Tx = Parameters<
  Parameters<DatabaseConnection['db']['transaction']>[0]
>[0];

type MaintenanceRecord =
  typeof maintenanceRecords.$inferSelect;

export interface MaintenanceActor {
  userId: string;
  role: UserRole;
  ip: string | null;
}

const ACTIVE_COMMAND_STATUSES = [
  'PENDING',
  'SENT',
  'ACKNOWLEDGED',
] as const;

const ACTIVE_TRANSFER_STATUSES = [
  'PENDING',
  'IN_TRANSIT',
  'FAILED',
] as const;

const STAFF_ROLES: UserRole[] = [
  'TECHNICIAN',
  'ADMIN',
  'SUPER_ADMIN',
];

const isAdmin = (role: UserRole): boolean =>
  role === 'ADMIN' || role === 'SUPER_ADMIN';

// ==========================================
// MAINTENANCE SERVICE
// ==========================================
//
// What starting / finishing a job does to its target:
//
//   STATION     ONLINE|OFFLINE -> MAINTENANCE -> previous status
//   PORT        EMPTY|DISABLED -> MAINTENANCE -> EMPTY
//   POWER_BANK  AVAILABLE      -> MAINTENANCE -> AVAILABLE
//               (taken out of its port with a MAINTENANCE_OUT
//                movement, optionally put back with a
//                MAINTENANCE_RETURN movement)
//
// Every change and its audit row share one transaction.

@Injectable()
export class MaintenanceService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,

    @Inject(AuditLogsService)
    private readonly auditLogs: AuditLogsService,
  ) {}

  // ==========================================
  // CREATE (OPEN) — target is not touched yet
  // ==========================================

  async create(
    dto: CreateMaintenanceDto,
    actor: MaintenanceActor,
  ) {
    try {
      return await this.connection.db.transaction(
        async (tx) => {
          const target = await this.resolveTarget(
            tx,
            dto.targetType,
            dto.targetId,
          );

          const [record] = await tx
            .insert(maintenanceRecords)
            .values({
              targetType: dto.targetType,
              stationId: target.stationId,
              portId: target.portId,
              powerBankId: target.powerBankId,
              maintenanceType: dto.maintenanceType,
              priority: dto.priority ?? 'MEDIUM',
              title: dto.title.trim(),
              description: dto.description?.trim() || null,
              reportedBy: actor.userId,
            })
            .returning();

          await this.auditLogs.record(
            {
              userId: actor.userId,
              action: 'CREATE',
              entityType: 'maintenance_record',
              entityId: record.id,
              newValues: record,
              ipAddress: actor.ip,
            },
            tx,
          );

          return record;
        },
      );
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          'This target already has an active maintenance record',
        );
      }

      throw error;
    }
  }

  // ==========================================
  // LIST (paginated + filtered)
  // ==========================================

  async findAll(query: FindMaintenanceQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    const targetFilter = query.targetId
      ? query.targetType === 'STATION'
        ? eq(maintenanceRecords.stationId, query.targetId)
        : query.targetType === 'PORT'
          ? eq(maintenanceRecords.portId, query.targetId)
          : query.targetType === 'POWER_BANK'
            ? eq(
                maintenanceRecords.powerBankId,
                query.targetId,
              )
            : or(
                eq(
                  maintenanceRecords.stationId,
                  query.targetId,
                ),
                eq(maintenanceRecords.portId, query.targetId),
                eq(
                  maintenanceRecords.powerBankId,
                  query.targetId,
                ),
              )
      : undefined;

    const whereCondition = and(
      query.status
        ? eq(maintenanceRecords.status, query.status)
        : undefined,

      query.targetType
        ? eq(maintenanceRecords.targetType, query.targetType)
        : undefined,

      targetFilter,

      query.maintenanceType
        ? eq(
            maintenanceRecords.maintenanceType,
            query.maintenanceType,
          )
        : undefined,

      query.priority
        ? eq(maintenanceRecords.priority, query.priority)
        : undefined,

      query.assignedTo
        ? eq(maintenanceRecords.assignedTo, query.assignedTo)
        : undefined,
    );

    const [data, countResult] = await Promise.all([
      this.selectWithPeople()
        .where(whereCondition)
        .orderBy(
          desc(maintenanceRecords.createdAt),
          desc(maintenanceRecords.id),
        )
        .limit(limit)
        .offset(offset),

      this.connection.db
        .select({ total: count() })
        .from(maintenanceRecords)
        .where(whereCondition),
    ]);

    const total = countResult[0]?.total ?? 0;
    const totalPages = Math.ceil(total / limit);

    return {
      data: data.map((row) => this.shape(row)),

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
  // GET ONE
  // ==========================================

  async findOne(id: string) {
    const [row] = await this.selectWithPeople()
      .where(eq(maintenanceRecords.id, id))
      .limit(1);

    if (!row) {
      throw new NotFoundException(
        'Maintenance record not found',
      );
    }

    return this.shape(row);
  }

  // ==========================================
  // START: OPEN -> IN_PROGRESS
  // Moves the target into MAINTENANCE
  // ==========================================

  async start(id: string, actor: MaintenanceActor) {
    return this.connection.db.transaction(async (tx) => {
      const record = await this.lockRecord(tx, id);

      if (record.status !== 'OPEN') {
        throw new ConflictException(
          `Only OPEN records can be started (current status: ${record.status})`,
        );
      }

      if (
        record.assignedTo &&
        record.assignedTo !== actor.userId &&
        !isAdmin(actor.role)
      ) {
        throw new ForbiddenException(
          'This maintenance record is assigned to another technician',
        );
      }

      const previousStatus = await this.enterMaintenance(
        tx,
        record,
        actor,
      );

      const now = new Date();

      const [updated] = await tx
        .update(maintenanceRecords)
        .set({
          status: 'IN_PROGRESS',
          startedAt: now,
          assignedTo: record.assignedTo ?? actor.userId,
          previousStatus,
          updatedAt: now,
        })
        .where(eq(maintenanceRecords.id, id))
        .returning();

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'maintenance_record',
          entityId: id,
          oldValues: { status: record.status },
          newValues: {
            status: updated.status,
            assignedTo: updated.assignedTo,
            previousStatus,
          },
          ipAddress: actor.ip,
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // COMPLETE: IN_PROGRESS -> COMPLETED
  // Restores the target
  // ==========================================

  async complete(
    id: string,
    dto: CompleteMaintenanceDto,
    actor: MaintenanceActor,
  ) {
    return this.connection.db.transaction(async (tx) => {
      const record = await this.lockRecord(tx, id);

      if (record.status !== 'IN_PROGRESS') {
        throw new ConflictException(
          `Only IN_PROGRESS records can be completed (current status: ${record.status})`,
        );
      }

      this.assertCanWork(record, actor);

      await this.exitMaintenance(tx, record, actor, {
        returnPortId: dto.returnPortId,
        stationStatusAfter: dto.stationStatusAfter,
      });

      const now = new Date();

      const [updated] = await tx
        .update(maintenanceRecords)
        .set({
          status: 'COMPLETED',
          completedAt: now,
          resolutionNotes: dto.resolutionNotes.trim(),
          updatedAt: now,
        })
        .where(eq(maintenanceRecords.id, id))
        .returning();

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'maintenance_record',
          entityId: id,
          oldValues: { status: record.status },
          newValues: {
            status: updated.status,
            resolutionNotes: updated.resolutionNotes,
          },
          ipAddress: actor.ip,
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // CANCEL: OPEN | IN_PROGRESS -> CANCELLED
  // ==========================================

  async cancel(
    id: string,
    dto: CancelMaintenanceDto,
    actor: MaintenanceActor,
  ) {
    return this.connection.db.transaction(async (tx) => {
      const record = await this.lockRecord(tx, id);

      // Idempotent
      if (record.status === 'CANCELLED') {
        return record;
      }

      if (
        record.status !== 'OPEN' &&
        record.status !== 'IN_PROGRESS'
      ) {
        throw new ConflictException(
          `Maintenance record cannot be cancelled (current status: ${record.status})`,
        );
      }

      const mayCancel =
        isAdmin(actor.role) ||
        record.assignedTo === actor.userId ||
        (record.status === 'OPEN' &&
          record.reportedBy === actor.userId);

      if (!mayCancel) {
        throw new ForbiddenException(
          'You are not allowed to cancel this maintenance record',
        );
      }

      if (record.status === 'IN_PROGRESS') {
        await this.exitMaintenance(tx, record, actor, {});
      }

      const now = new Date();

      const [updated] = await tx
        .update(maintenanceRecords)
        .set({
          status: 'CANCELLED',
          cancelledAt: now,
          resolutionNotes: dto.reason?.trim() || null,
          updatedAt: now,
        })
        .where(eq(maintenanceRecords.id, id))
        .returning();

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'maintenance_record',
          entityId: id,
          oldValues: { status: record.status },
          newValues: {
            status: updated.status,
            reason: updated.resolutionNotes,
          },
          ipAddress: actor.ip,
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // ASSIGN (admin)
  // ==========================================

  async assign(
    id: string,
    dto: AssignMaintenanceDto,
    actor: MaintenanceActor,
  ) {
    return this.connection.db.transaction(async (tx) => {
      const record = await this.lockRecord(tx, id);

      if (
        record.status !== 'OPEN' &&
        record.status !== 'IN_PROGRESS'
      ) {
        throw new ConflictException(
          `Cannot assign a ${record.status} maintenance record`,
        );
      }

      const [assignee] = await tx
        .select({
          id: users.id,
          role: users.role,
          isActive: users.isActive,
        })
        .from(users)
        .where(eq(users.id, dto.assignedTo))
        .limit(1);

      if (!assignee) {
        throw new NotFoundException('Assignee not found');
      }

      if (!assignee.isActive) {
        throw new BadRequestException(
          'Assignee account is not active',
        );
      }

      if (!STAFF_ROLES.includes(assignee.role)) {
        throw new BadRequestException(
          'Assignee must be a technician or an administrator',
        );
      }

      const [updated] = await tx
        .update(maintenanceRecords)
        .set({
          assignedTo: assignee.id,
          updatedAt: new Date(),
        })
        .where(eq(maintenanceRecords.id, id))
        .returning();

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'UPDATE',
          entityType: 'maintenance_record',
          entityId: id,
          oldValues: { assignedTo: record.assignedTo },
          newValues: { assignedTo: updated.assignedTo },
          ipAddress: actor.ip,
        },
        tx,
      );

      return updated;
    });
  }

  // ==========================================
  // INTERNAL: TARGET LOOKUP (for create)
  // ==========================================

  private async resolveTarget(
    tx: Tx,
    targetType: MaintenanceRecord['targetType'],
    targetId: string,
  ): Promise<{
    stationId: string | null;
    portId: string | null;
    powerBankId: string | null;
  }> {
    if (targetType === 'STATION') {
      const [station] = await tx
        .select({ id: stations.id })
        .from(stations)
        .where(eq(stations.id, targetId))
        .limit(1);

      if (!station) {
        throw new NotFoundException('Station not found');
      }

      return {
        stationId: station.id,
        portId: null,
        powerBankId: null,
      };
    }

    if (targetType === 'PORT') {
      const [port] = await tx
        .select({
          id: ports.id,
          stationId: ports.stationId,
        })
        .from(ports)
        .where(eq(ports.id, targetId))
        .limit(1);

      if (!port) {
        throw new NotFoundException('Port not found');
      }

      return {
        stationId: port.stationId,
        portId: port.id,
        powerBankId: null,
      };
    }

    const [bank] = await tx
      .select({ id: powerBanks.id })
      .from(powerBanks)
      .where(eq(powerBanks.id, targetId))
      .limit(1);

    if (!bank) {
      throw new NotFoundException('Power Bank not found');
    }

    return {
      stationId: null,
      portId: null,
      powerBankId: bank.id,
    };
  }

  // ==========================================
  // INTERNAL: ENTER MAINTENANCE
  // Returns the target's previous status
  // ==========================================

  private async enterMaintenance(
    tx: Tx,
    record: MaintenanceRecord,
    actor: MaintenanceActor,
  ): Promise<string> {
    if (record.targetType === 'STATION') {
      const [station] = await tx
        .select()
        .from(stations)
        .where(eq(stations.id, record.stationId as string))
        .limit(1)
        .for('update');

      if (!station) {
        throw new NotFoundException('Station not found');
      }

      if (station.status === 'MAINTENANCE') {
        throw new ConflictException(
          'Station is already in maintenance',
        );
      }

      const [pendingRental] = await tx
        .select({ id: rentals.id })
        .from(rentals)
        .where(
          and(
            eq(rentals.pickupStationId, station.id),
            eq(rentals.status, 'PENDING'),
          ),
        )
        .limit(1);

      if (pendingRental) {
        throw new ConflictException(
          'Station has pending rentals',
        );
      }

      await this.assertNoActiveCommand(tx, {
        stationId: station.id,
      });

      await tx
        .update(stations)
        .set({
          status: 'MAINTENANCE',
          updatedAt: new Date(),
        })
        .where(eq(stations.id, station.id));

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'station',
          entityId: station.id,
          oldValues: { status: station.status },
          newValues: { status: 'MAINTENANCE' },
          ipAddress: actor.ip,
        },
        tx,
      );

      return station.status;
    }

    if (record.targetType === 'PORT') {
      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, record.portId as string))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException('Port not found');
      }

      if (port.status === 'MAINTENANCE') {
        throw new ConflictException(
          'Port is already in maintenance',
        );
      }

      if (port.status === 'OCCUPIED') {
        throw new ConflictException(
          'Port contains a Power Bank: move it out before maintenance',
        );
      }

      await this.assertPortIsFree(tx, port.id);

      await tx
        .update(ports)
        .set({
          status: 'MAINTENANCE',
          updatedAt: new Date(),
        })
        .where(eq(ports.id, port.id));

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'port',
          entityId: port.id,
          oldValues: { status: port.status },
          newValues: { status: 'MAINTENANCE' },
          ipAddress: actor.ip,
        },
        tx,
      );

      return port.status;
    }

    // POWER_BANK

    const [bank] = await tx
      .select()
      .from(powerBanks)
      .where(
        eq(powerBanks.id, record.powerBankId as string),
      )
      .limit(1)
      .for('update');

    if (!bank) {
      throw new NotFoundException('Power Bank not found');
    }

    if (bank.status !== 'AVAILABLE') {
      throw new ConflictException(
        `Power Bank must be AVAILABLE for maintenance (current status: ${bank.status})`,
      );
    }

    const [activeRental] = await tx
      .select({ id: rentals.id })
      .from(rentals)
      .where(
        and(
          eq(rentals.powerBankId, bank.id),
          inArray(rentals.status, ['PENDING', 'ACTIVE']),
        ),
      )
      .limit(1);

    if (activeRental) {
      throw new ConflictException(
        'Power Bank has an active rental',
      );
    }

    const [transferItem] = await tx
      .select({ id: transferMissionItems.id })
      .from(transferMissionItems)
      .where(
        and(
          eq(transferMissionItems.powerBankId, bank.id),
          inArray(transferMissionItems.status, [
            ...ACTIVE_TRANSFER_STATUSES,
          ]),
        ),
      )
      .limit(1);

    if (transferItem) {
      throw new ConflictException(
        'Power Bank is involved in an active transfer',
      );
    }

    // Take it out of its port (if it is in one)

    if (bank.currentPortId) {
      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, bank.currentPortId))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException('Port not found');
      }

      await this.assertNoActiveCommand(tx, {
        portId: port.id,
      });

      await tx
        .update(ports)
        .set({ status: 'EMPTY', updatedAt: new Date() })
        .where(eq(ports.id, port.id));

      await tx.insert(powerBankMovements).values({
        powerBankId: bank.id,
        fromStationId: port.stationId,
        fromPortId: port.id,
        performedBy: actor.userId,
        movementType: 'MAINTENANCE_OUT',
        notes: `Maintenance record ${record.id}`,
      });

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'port',
          entityId: port.id,
          oldValues: { status: port.status },
          newValues: { status: 'EMPTY' },
          ipAddress: actor.ip,
        },
        tx,
      );
    }

    await tx
      .update(powerBanks)
      .set({
        status: 'MAINTENANCE',
        currentPortId: null,
        updatedAt: new Date(),
      })
      .where(eq(powerBanks.id, bank.id));

    await this.auditLogs.record(
      {
        userId: actor.userId,
        action: 'STATUS_CHANGE',
        entityType: 'power_bank',
        entityId: bank.id,
        oldValues: {
          status: bank.status,
          currentPortId: bank.currentPortId,
        },
        newValues: {
          status: 'MAINTENANCE',
          currentPortId: null,
        },
        ipAddress: actor.ip,
      },
      tx,
    );

    return bank.status;
  }

  // ==========================================
  // INTERNAL: EXIT MAINTENANCE (complete / cancel)
  // ==========================================

  private async exitMaintenance(
    tx: Tx,
    record: MaintenanceRecord,
    actor: MaintenanceActor,
    options: {
      returnPortId?: string | undefined;
      stationStatusAfter?: 'ONLINE' | 'OFFLINE' | undefined;
    },
  ): Promise<void> {
    if (
      options.returnPortId &&
      record.targetType !== 'POWER_BANK'
    ) {
      throw new BadRequestException(
        'returnPortId applies to Power Bank maintenance only',
      );
    }

    if (
      options.stationStatusAfter &&
      record.targetType !== 'STATION'
    ) {
      throw new BadRequestException(
        'stationStatusAfter applies to station maintenance only',
      );
    }

    if (record.targetType === 'STATION') {
      const [station] = await tx
        .select()
        .from(stations)
        .where(eq(stations.id, record.stationId as string))
        .limit(1)
        .for('update');

      if (!station) {
        throw new NotFoundException('Station not found');
      }

      if (station.status !== 'MAINTENANCE') {
        throw new ConflictException(
          'Station status was changed outside this maintenance record',
        );
      }

      const restored: 'ONLINE' | 'OFFLINE' =
        options.stationStatusAfter ??
        (record.previousStatus === 'ONLINE'
          ? 'ONLINE'
          : 'OFFLINE');

      await tx
        .update(stations)
        .set({ status: restored, updatedAt: new Date() })
        .where(eq(stations.id, station.id));

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'station',
          entityId: station.id,
          oldValues: { status: station.status },
          newValues: { status: restored },
          ipAddress: actor.ip,
        },
        tx,
      );

      return;
    }

    if (record.targetType === 'PORT') {
      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, record.portId as string))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException('Port not found');
      }

      if (port.status !== 'MAINTENANCE') {
        throw new ConflictException(
          'Port status was changed outside this maintenance record',
        );
      }

      await tx
        .update(ports)
        .set({ status: 'EMPTY', updatedAt: new Date() })
        .where(eq(ports.id, port.id));

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'port',
          entityId: port.id,
          oldValues: { status: port.status },
          newValues: { status: 'EMPTY' },
          ipAddress: actor.ip,
        },
        tx,
      );

      return;
    }

    // POWER_BANK

    const [bank] = await tx
      .select()
      .from(powerBanks)
      .where(
        eq(powerBanks.id, record.powerBankId as string),
      )
      .limit(1)
      .for('update');

    if (!bank) {
      throw new NotFoundException('Power Bank not found');
    }

    if (bank.status !== 'MAINTENANCE') {
      throw new ConflictException(
        'Power Bank status was changed outside this maintenance record',
      );
    }

    let returnedToPortId: string | null = null;

    if (options.returnPortId) {
      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, options.returnPortId))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException('Return port not found');
      }

      if (port.status !== 'EMPTY') {
        throw new ConflictException(
          'Return port must be EMPTY',
        );
      }

      const [occupant] = await tx
        .select({ id: powerBanks.id })
        .from(powerBanks)
        .where(eq(powerBanks.currentPortId, port.id))
        .limit(1);

      if (occupant) {
        throw new ConflictException(
          'Return port already contains a Power Bank',
        );
      }

      await this.assertPortIsFree(tx, port.id);

      await tx
        .update(ports)
        .set({ status: 'OCCUPIED', updatedAt: new Date() })
        .where(eq(ports.id, port.id));

      await tx.insert(powerBankMovements).values({
        powerBankId: bank.id,
        toStationId: port.stationId,
        toPortId: port.id,
        performedBy: actor.userId,
        movementType: 'MAINTENANCE_RETURN',
        notes: `Maintenance record ${record.id}`,
      });

      await this.auditLogs.record(
        {
          userId: actor.userId,
          action: 'STATUS_CHANGE',
          entityType: 'port',
          entityId: port.id,
          oldValues: { status: port.status },
          newValues: { status: 'OCCUPIED' },
          ipAddress: actor.ip,
        },
        tx,
      );

      returnedToPortId = port.id;
    }

    await tx
      .update(powerBanks)
      .set({
        status: 'AVAILABLE',
        currentPortId: returnedToPortId,
        updatedAt: new Date(),
      })
      .where(eq(powerBanks.id, bank.id));

    await this.auditLogs.record(
      {
        userId: actor.userId,
        action: 'STATUS_CHANGE',
        entityType: 'power_bank',
        entityId: bank.id,
        oldValues: {
          status: bank.status,
          currentPortId: bank.currentPortId,
        },
        newValues: {
          status: 'AVAILABLE',
          currentPortId: returnedToPortId,
        },
        ipAddress: actor.ip,
      },
      tx,
    );
  }

  // ==========================================
  // INTERNAL: SAFETY CHECKS
  // (same rules PortsService enforces)
  // ==========================================

  private async assertPortIsFree(
    tx: Tx,
    portId: string,
  ): Promise<void> {
    const [bank] = await tx
      .select({ id: powerBanks.id })
      .from(powerBanks)
      .where(eq(powerBanks.currentPortId, portId))
      .limit(1);

    if (bank) {
      throw new ConflictException(
        'Port contains a Power Bank',
      );
    }

    const [rental] = await tx
      .select({ id: rentals.id })
      .from(rentals)
      .where(
        or(
          and(
            eq(rentals.status, 'PENDING'),
            eq(rentals.pickupPortId, portId),
          ),
          and(
            eq(rentals.status, 'ACTIVE'),
            eq(rentals.returnPortId, portId),
          ),
        ),
      )
      .limit(1);

    if (rental) {
      throw new ConflictException(
        'Port is reserved by a rental',
      );
    }

    const [transferItem] = await tx
      .select({ id: transferMissionItems.id })
      .from(transferMissionItems)
      .where(
        and(
          inArray(transferMissionItems.status, [
            ...ACTIVE_TRANSFER_STATUSES,
          ]),
          or(
            eq(transferMissionItems.fromPortId, portId),
            eq(transferMissionItems.toPortId, portId),
          ),
        ),
      )
      .limit(1);

    if (transferItem) {
      throw new ConflictException(
        'Port is involved in an active transfer',
      );
    }

    await this.assertNoActiveCommand(tx, { portId });
  }

  // A device command that is still live (not expired)
  // means the hardware is busy: do not take it out of service.
  private async assertNoActiveCommand(
    tx: Tx,
    scope: { stationId?: string; portId?: string },
  ): Promise<void> {
    const now = new Date();

    const [command] = await tx
      .select({ id: deviceCommands.id })
      .from(deviceCommands)
      .where(
        and(
          scope.stationId
            ? eq(deviceCommands.stationId, scope.stationId)
            : undefined,
          scope.portId
            ? eq(deviceCommands.portId, scope.portId)
            : undefined,
          inArray(deviceCommands.status, [
            ...ACTIVE_COMMAND_STATUSES,
          ]),
          or(
            isNull(deviceCommands.expiresAt),
            gt(deviceCommands.expiresAt, now),
          ),
        ),
      )
      .limit(1);

    if (command) {
      throw new ConflictException(
        'An active device command exists for this target',
      );
    }
  }

  // ==========================================
  // INTERNAL: HELPERS
  // ==========================================

  private async lockRecord(tx: Tx, id: string) {
    const [record] = await tx
      .select()
      .from(maintenanceRecords)
      .where(eq(maintenanceRecords.id, id))
      .limit(1)
      .for('update');

    if (!record) {
      throw new NotFoundException(
        'Maintenance record not found',
      );
    }

    return record;
  }

  private assertCanWork(
    record: MaintenanceRecord,
    actor: MaintenanceActor,
  ): void {
    if (
      !isAdmin(actor.role) &&
      record.assignedTo !== actor.userId
    ) {
      throw new ForbiddenException(
        'Only the assigned technician or an administrator can do this',
      );
    }
  }

  private selectWithPeople() {
    const reporter = alias(users, 'reporter');
    const assignee = alias(users, 'assignee');

    return this.connection.db
      .select({
        record: maintenanceRecords,
        reporter: {
          id: reporter.id,
          fullName: reporter.fullName,
        },
        assignee: {
          id: assignee.id,
          fullName: assignee.fullName,
        },
      })
      .from(maintenanceRecords)
      .leftJoin(
        reporter,
        eq(maintenanceRecords.reportedBy, reporter.id),
      )
      .leftJoin(
        assignee,
        eq(maintenanceRecords.assignedTo, assignee.id),
      );
  }

  private shape(row: {
    record: MaintenanceRecord;
    reporter: { id: string; fullName: string } | null;
    assignee: { id: string; fullName: string } | null;
  }) {
    return {
      ...row.record,
      reporter: row.reporter,
      assignee: row.assignee,
    };
  }
}
