
import {
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { asc, eq } from 'drizzle-orm';

import { DATABASE_CONNECTION } from '../../database/database.constants.js';
import type { databaseProvider } from '../../database/database.provider.js';

import { ports } from '../../database/schema/ports.schema.js';
import { stations } from '../../database/schema/stations.schema.js';

type DatabaseConnection = Awaited<
  ReturnType<typeof databaseProvider.useFactory>
>;

@Injectable()
export class PortsService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: DatabaseConnection,
  ) {}

  // GET all ports
  async findAll() {
    return this.connection.db
      .select()
      .from(ports)
      .orderBy(
        asc(ports.stationId),
        asc(ports.portNumber),
      );
  }

  // GET one port by ID
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

  // GET all ports belonging to a station
  async findByStation(stationId: string) {
    // Check if station exists
    const [station] = await this.connection.db
      .select()
      .from(stations)
      .where(eq(stations.id, stationId))
      .limit(1);

    if (!station) {
      throw new NotFoundException('Station not found');
    }

    // Get station ports
    return this.connection.db
      .select()
      .from(ports)
      .where(eq(ports.stationId, stationId))
      .orderBy(asc(ports.portNumber));
  }
}
