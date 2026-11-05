
import { Global, Module } from '@nestjs/common';
import { databaseProvider } from './database.provider.js';
import { DatabaseShutdown } from './database.shutdown.js';
import { DatabaseController } from './database.controller.js';

@Global()
@Module({
  controllers: [DatabaseController],
  providers: [databaseProvider, DatabaseShutdown],
  exports: [databaseProvider],
})
export class DatabaseModule {}
