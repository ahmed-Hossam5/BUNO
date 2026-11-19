
import {
  Inject,
  Injectable,
  OnApplicationShutdown,
} from '@nestjs/common';
import { Pool } from 'pg';
import { DATABASE_CONNECTION } from './database.constants.js';

@Injectable()
export class DatabaseShutdown implements OnApplicationShutdown {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private readonly connection: {
      pool: Pool;
    },
  ) {}

  async onApplicationShutdown(): Promise<void> {
    await this.connection.pool.end();
  }
}
