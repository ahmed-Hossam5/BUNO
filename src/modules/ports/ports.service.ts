
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
  eq,
  inArray,
  or,
} from 'drizzle-orm';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import type { databaseProvider } from '../../database/database.provider.js';

import { ports } from '../../database/schema/ports.schema.js';
import { stations } from '../../database/schema/stations.schema.js';
import { powerBanks } from '../../database/schema/power-banks.schema.js';
import { rentals } from '../../database/schema/rentals.schema.js';
import { transferMissionItems } from '../../database/schema/transfer-mission-items.schema.js';

import { UpdatePortStatusDto } from './dto/update-port-status.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

@Injectable()
export class PortsService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {}

  // ==========================================
  // GET ALL PORTS
  // ==========================================

  async findAll() {
    return this.connection.db
      .select()
      .from(ports)
      .orderBy(
        asc(ports.stationId),
        asc(ports.portNumber),
      );
  }

  // ==========================================
  // GET ONE PORT BY ID
  // ==========================================

  async findOne(id: string) {
    const [port] = await this.connection.db
      .select()
      .from(ports)
      .where(eq(ports.id, id))
      .limit(1);

    if (!port) {
      throw new NotFoundException('Port not found');
    }

    return port;
  }

  // ==========================================
  // GET PORTS BY STATION
  // ==========================================

  async findByStation(stationId: string) {
    // 1. Check if station exists
    const [station] = await this.connection.db
      .select()
      .from(stations)
      .where(eq(stations.id, stationId))
      .limit(1);

    if (!station) {
      throw new NotFoundException('Station not found');
    }

    // 2. Get station ports
    return this.connection.db
      .select()
      .from(ports)
      .where(eq(ports.stationId, stationId))
      .orderBy(asc(ports.portNumber));
  }

  // ==========================================
  // UPDATE PORT STATUS
  // ==========================================

  async updateStatus(
    id: string,
    dto: UpdatePortStatusDto,
  ) {
    return this.connection.db.transaction(async (tx) => {

      // 1. Find and lock port
      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, id))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException('Port not found');
      }

      // 2. OCCUPIED is managed automatically
      if (dto.status === 'OCCUPIED') {
        throw new BadRequestException(
          'OCCUPIED status is managed automatically by Power Bank operations',
        );
      }

      // 3. Check if status is already the same
      if (port.status === dto.status) {
        return port;
      }

      // 4. Check if a Power Bank exists in this port
      const [powerBank] = await tx
        .select({
          id: powerBanks.id,
        })
        .from(powerBanks)
        .where(eq(powerBanks.currentPortId, id))
        .limit(1);

      if (powerBank) {
        throw new ConflictException(
          'Cannot change status: port contains a Power Bank',
        );
      }

      // 5. Check active rental reservations
      const [rental] = await tx
        .select({
          id: rentals.id,
        })
        .from(rentals)
        .where(
          or(
            and(
              eq(rentals.status, 'PENDING'),
              eq(rentals.pickupPortId, id),
            ),
            and(
              eq(rentals.status, 'ACTIVE'),
              eq(rentals.returnPortId, id),
            ),
          ),
        )
        .limit(1);

      if (rental) {
        throw new ConflictException(
          'Cannot change status: port is reserved by a rental',
        );
      }

      // 6. Check active transfer operations
      const [transferItem] = await tx
        .select({
          id: transferMissionItems.id,
        })
        .from(transferMissionItems)
        .where(
          and(
            inArray(transferMissionItems.status, [
              'PENDING',
              'IN_TRANSIT',
              'FAILED',
            ]),
            or(
              eq(transferMissionItems.fromPortId, id),
              eq(transferMissionItems.toPortId, id),
            ),
          ),
        )
        .limit(1);

      if (transferItem) {
        throw new ConflictException(
          'Cannot change status: port is involved in an active transfer',
        );
      }

      // 7. Update port status
      const [updatedPort] = await tx
        .update(ports)
        .set({
          status: dto.status,
          updatedAt: new Date(),
        })
        .where(eq(ports.id, id))
        .returning();

      if (!updatedPort) {
        throw new NotFoundException('Port not found');
      }

      return updatedPort;
    });
  }
}
