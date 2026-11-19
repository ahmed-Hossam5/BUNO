
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
  eq,
  ilike,
  or,
} from 'drizzle-orm';

import { FindStationsQueryDto } from './dto/find-stations-query.dto.js';
import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import { isUniqueViolation } from '../../database/database-errors.js';
import type { databaseProvider } from '../../database/database.provider.js';

import { stations } from '../../database/schema/stations.schema.js';
import { ports } from '../../database/schema/ports.schema.js';

import { CreateStationDto } from './dto/create-station.dto.js';
import { UpdateStationDto } from './dto/update-station.dto.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

@Injectable()
export class StationsService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {}

  // Create a station with its ports
  async create(dto: CreateStationDto) {
    try {
      return await this.connection.db.transaction(async (tx) => {
        // 1. Create station
        const [station] = await tx
          .insert(stations)
          .values({
            stationCode: dto.stationCode.trim(),
            name: dto.name.trim(),
            totalPorts: dto.totalPorts ?? 4,
          })
          .returning();

        // 2. Prepare ports
        const portValues = Array.from(
          { length: station.totalPorts },
          (_, index) => ({
            stationId: station.id,
            portNumber: index + 1,
          }),
        );

        // 3. Create all ports
        const createdPorts = await tx
          .insert(ports)
          .values(portValues)
          .returning();

        // 4. Return station with ports
        return {
          ...station,
          ports: createdPorts,
        };
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          'A station with this station code already exists',
        );
      }

      throw error;
    }
  }

  // Get all stations
  
  // Get all stations with pagination, search and filtering
  async findAll(query: FindStationsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 10;

    const offset = (page - 1) * limit;

    const search = query.search?.trim();

    // Build filters
    const whereCondition = and(
      search
        ? or(
            ilike(stations.name, `%${search}%`),
            ilike(stations.stationCode, `%${search}%`),
          )
        : undefined,

      query.status
        ? eq(stations.status, query.status)
        : undefined,
    );

    // Fetch data and total count
    const [data, countResult] = await Promise.all([
      this.connection.db
        .select()
        .from(stations)
        .where(whereCondition)
        .orderBy(
                asc(stations.createdAt),
                asc(stations.id),
                )
        .limit(limit)
        .offset(offset),

      this.connection.db
        .select({
          total: count(),
        })
        .from(stations)
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


  // Get one station with its ports
  async findOne(id: string) {
    // 1. Find station
    const [station] = await this.connection.db
      .select()
      .from(stations)
      .where(eq(stations.id, id))
      .limit(1);

    // 2. Check if station exists
    if (!station) {
      throw new NotFoundException('Station not found');
    }

    // 3. Get station ports
    const stationPorts = await this.connection.db
      .select()
      .from(ports)
      .where(eq(ports.stationId, id))
      .orderBy(asc(ports.portNumber));

    // 4. Return station with ports
    return {
      ...station,
      ports: stationPorts,
    };
  }

  // Update station
  async update(id: string, dto: UpdateStationDto) {
    // 1. Check that at least one field was provided
    if (
      dto.stationCode === undefined &&
      dto.name === undefined
    ) {
      throw new BadRequestException(
        'At least one field must be provided',
      );
    }

    try {
      // 2. Update station
      const [updatedStation] = await this.connection.db
        .update(stations)
        .set({
          ...(dto.stationCode !== undefined && {
            stationCode: dto.stationCode.trim(),
          }),

          ...(dto.name !== undefined && {
            name: dto.name.trim(),
          }),

          updatedAt: new Date(),
        })
        .where(eq(stations.id, id))
        .returning();

      // 3. Check if station exists
      if (!updatedStation) {
        throw new NotFoundException('Station not found');
      }

      return updatedStation;

    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          'A station with this station code already exists',
        );
      }

      throw error;
    }
  }
}
