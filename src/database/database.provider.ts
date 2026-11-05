
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import { DATABASE_CONNECTION } from './database.constants.js';

export const databaseProvider = {
  provide: DATABASE_CONNECTION,

  useFactory: async () => {
    const connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
      throw new Error('DATABASE_URL is not defined');
    }

    const pool = new Pool({
      connectionString,
      max: 10,
    });

    try {
      await pool.query('SELECT 1');
    } catch (error) {
      await pool.end();
      throw error;
    }

    return {
      db: drizzle({ client: pool }),
      pool,
    };
  },
};
