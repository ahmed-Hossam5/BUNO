
import {
  Controller,
  Get,
  Inject,
  ServiceUnavailableException,
} from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { DATABASE_CONNECTION } from './database/database.constants.js';

@Controller('database')
export class DatabaseController {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: {
      db: ReturnType<typeof import('drizzle-orm/node-postgres').drizzle>;
    },
  ) {}

  @Get('health')
  async checkConnection() {
    try {
      const result = await this.connection.db.execute(
        sql`SELECT version()`,
      );

      return {
        status: 'connected',
        database: 'buno_db',
        version: result.rows[0],
      };
    } catch {
      throw new ServiceUnavailableException(
        'Database connection failed',
      );
    }
  }
}
