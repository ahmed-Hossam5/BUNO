
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
  desc,
  eq,
  inArray,
  or,
} from 'drizzle-orm';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import { isUniqueViolation } from '../../database/database-errors.js';
import type { databaseProvider } from '../../database/database.provider.js';

import { powerBanks } from '../../database/schema/power-banks.schema.js';
import { ports } from '../../database/schema/ports.schema.js';
import { stations } from '../../database/schema/stations.schema.js';
import { powerBankMovements } from '../../database/schema/power-bank-movements.schema.js';
import { rentals } from '../../database/schema/rentals.schema.js';
import { transferMissionItems } from '../../database/schema/transfer-mission-items.schema.js';

import { CreatePowerBankDto } from './dto/create-power-bank.dto.js';
import { PlacePowerBankDto } from './dto/place-power-bank.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

@Injectable()
export class PowerBanksService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {}

  // ==========================================
  // GET ALL POWER BANKS
  // ==========================================

  async findAll() {
    const result = await this.connection.db
      .select({
        powerBank: powerBanks,
        currentPort: ports,
      })
      .from(powerBanks)
      .leftJoin(
        ports,
        eq(powerBanks.currentPortId, ports.id),
      )
      .orderBy(asc(powerBanks.createdAt));

    return result.map(({ powerBank, currentPort }) => ({
      ...powerBank,
      currentPort,
    }));
  }

  // ==========================================
  // GET POWER BANK BY ID
  // ==========================================

  async findOne(id: string) {
    const [result] = await this.connection.db
      .select({
        powerBank: powerBanks,
        currentPort: ports,
      })
      .from(powerBanks)
      .leftJoin(
        ports,
        eq(powerBanks.currentPortId, ports.id),
      )
      .where(eq(powerBanks.id, id))
      .limit(1);

    if (!result) {
      throw new NotFoundException(
        'Power Bank not found',
      );
    }

    return {
      ...result.powerBank,
      currentPort: result.currentPort,
    };
  }

  // ==========================================
  // CREATE POWER BANK
  // ==========================================

  async create(dto: CreatePowerBankDto) {
    const deviceIdentifier = dto.deviceIdentifier.trim();

    if (!deviceIdentifier) {
      throw new BadRequestException(
        'Device identifier cannot be empty',
      );
    }

    try {
      const [powerBank] = await this.connection.db
        .insert(powerBanks)
        .values({
          deviceIdentifier,
        })
        .returning();

      return powerBank;

    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          'A Power Bank with this identifier already exists',
        );
      }

      throw error;
    }
  }

  // ==========================================
  // INITIAL PLACEMENT
  // Place Power Bank inside a Port
  // ==========================================

  async place(
    id: string,
    dto: PlacePowerBankDto,
  ) {
    return this.connection.db.transaction(async (tx) => {

      // 1. Find and lock Power Bank

      const [powerBank] = await tx
        .select()
        .from(powerBanks)
        .where(eq(powerBanks.id, id))
        .limit(1)
        .for('update');

      if (!powerBank) {
        throw new NotFoundException(
          'Power Bank not found',
        );
      }

      // 2. Check Power Bank status

      if (powerBank.status !== 'AVAILABLE') {
        throw new ConflictException(
          'Power Bank is not available for placement',
        );
      }

      // 3. Check Power Bank is not already placed

      if (powerBank.currentPortId !== null) {
        throw new ConflictException(
          'Power Bank is already assigned to a port',
        );
      }

      // 4. Ensure this is the first placement

      const [previousMovement] = await tx
        .select({
          id: powerBankMovements.id,
        })
        .from(powerBankMovements)
        .where(
          eq(powerBankMovements.powerBankId, id),
        )
        .limit(1);

      if (previousMovement) {
        throw new ConflictException(
          'Initial placement has already been performed for this Power Bank',
        );
      }

      // 5. Find and lock destination Port

      const [port] = await tx
        .select()
        .from(ports)
        .where(eq(ports.id, dto.portId))
        .limit(1)
        .for('update');

      if (!port) {
        throw new NotFoundException(
          'Port not found',
        );
      }

      // 6. Port must be EMPTY

      if (port.status !== 'EMPTY') {
        throw new ConflictException(
          'Port is not available for placement',
        );
      }

      // 7. Check actual Power Bank occupancy

      const [existingPowerBank] = await tx
        .select({
          id: powerBanks.id,
        })
        .from(powerBanks)
        .where(
          eq(powerBanks.currentPortId, port.id),
        )
        .limit(1);

      if (existingPowerBank) {
        throw new ConflictException(
          'Port already contains a Power Bank',
        );
      }

      // 8. Check active rentals for Power Bank

      const [activeRental] = await tx
        .select({
          id: rentals.id,
        })
        .from(rentals)
        .where(
          and(
            eq(rentals.powerBankId, id),
            inArray(rentals.status, [
              'PENDING',
              'ACTIVE',
            ]),
          ),
        )
        .limit(1);

      if (activeRental) {
        throw new ConflictException(
          'Power Bank has an active rental',
        );
      }

      // 9. Check destination Port reservations

      const [portRental] = await tx
        .select({
          id: rentals.id,
        })
        .from(rentals)
        .where(
          or(
            and(
              eq(rentals.status, 'PENDING'),
              eq(rentals.pickupPortId, port.id),
            ),
            and(
              eq(rentals.status, 'ACTIVE'),
              eq(rentals.returnPortId, port.id),
            ),
          ),
        )
        .limit(1);

      if (portRental) {
        throw new ConflictException(
          'Port is reserved by an active rental',
        );
      }

      // 10. Check active transfer operations

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
              eq(transferMissionItems.powerBankId, id),
              eq(transferMissionItems.fromPortId, port.id),
              eq(transferMissionItems.toPortId, port.id),
            ),
          ),
        )
        .limit(1);

      if (transferItem) {
        throw new ConflictException(
          'Power Bank or Port is involved in an active transfer',
        );
      }

      // 11. Assign Power Bank to Port

      const [updatedPowerBank] = await tx
        .update(powerBanks)
        .set({
          currentPortId: port.id,
          updatedAt: new Date(),
        })
        .where(eq(powerBanks.id, id))
        .returning();

      // 12. Update Port status

      const [updatedPort] = await tx
        .update(ports)
        .set({
          status: 'OCCUPIED',
          updatedAt: new Date(),
        })
        .where(eq(ports.id, port.id))
        .returning();

      // 13. Record Initial Placement

      const [movement] = await tx
        .insert(powerBankMovements)
        .values({
          powerBankId: id,

          toStationId: port.stationId,
          toPortId: port.id,

          movementType: 'INITIAL_PLACEMENT',

          notes: 'Initial Power Bank placement',
        })
        .returning();

      // 14. Return complete result

      return {
        ...updatedPowerBank,
        currentPort: updatedPort,
        movement,
      };
    });
  }

  // ==========================================
  // GET POWER BANKS BY STATION
  // ==========================================

  async findByStation(stationId: string) {
    // 1. Check if station exists

    const [station] = await this.connection.db
      .select({
        id: stations.id,
      })
      .from(stations)
      .where(eq(stations.id, stationId))
      .limit(1);

    if (!station) {
      throw new NotFoundException(
        'Station not found',
      );
    }

    // 2. Get Power Banks currently located
    // in this station

    const result = await this.connection.db
      .select({
        powerBank: powerBanks,
        port: ports,
      })
      .from(powerBanks)
      .innerJoin(
        ports,
        eq(powerBanks.currentPortId, ports.id),
      )
      .where(eq(ports.stationId, stationId))
      .orderBy(asc(ports.portNumber));

    return result.map(({ powerBank, port }) => ({
      ...powerBank,
      currentPort: port,
    }));
  }

  // ==========================================
  // GET POWER BANK MOVEMENT HISTORY
  // ==========================================

  async findMovements(powerBankId: string) {
    // 1. Check Power Bank exists

    const [powerBank] = await this.connection.db
      .select({
        id: powerBanks.id,
      })
      .from(powerBanks)
      .where(eq(powerBanks.id, powerBankId))
      .limit(1);

    if (!powerBank) {
      throw new NotFoundException(
        'Power Bank not found',
      );
    }

    // 2. Get movement history

    return this.connection.db
      .select()
      .from(powerBankMovements)
      .where(
        eq(
          powerBankMovements.powerBankId,
          powerBankId,
        ),
      )
      .orderBy(desc(powerBankMovements.createdAt));
  }
}
