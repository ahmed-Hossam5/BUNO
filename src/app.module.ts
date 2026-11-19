
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { createObserveModule } from '@nestjs/observe';

import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { DatabaseModule } from './database/database.module.js';

import { UsersModule } from './modules/users/users.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { StationsModule } from './modules/stations/stations.module.js';
import { PowerBanksModule } from './modules/power-banks/power-banks.module.js';
import { RentalsModule } from './modules/rentals/rentals.module.js';
import { PaymentsModule } from './modules/payments/payments.module.js';
import { TelemetryModule } from './modules/telemetry/telemetry.module.js';
import { DeviceCommandsModule } from './modules/device-commands/device-commands.module.js';
import { MaintenanceModule } from './modules/maintenance/maintenance.module.js';
import { NotificationsModule } from './modules/notifications/notifications.module.js';
import { SupportModule } from './modules/support/support.module.js';
import { AuditLogsModule } from './modules/audit-logs/audit-logs.module.js';
import { PortsModule } from './modules/ports/ports.module.js';
import { ScheduleModule } from '@nestjs/schedule';

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    // Required by @Interval() jobs (notification worker,
    // device command sweeper). Without forRoot() they never run.
    ScheduleModule.forRoot(),

    DatabaseModule,

    ObserveModule.forRoot({
      appKey: 'YOUR_APP_KEY',
      appSecret: 'YOUR_APP_SECRET',
      serviceId: 'Back-end',
    }),

    UsersModule,
    AuthModule,
    StationsModule,
    PowerBanksModule,
    RentalsModule,
    PaymentsModule,
    TelemetryModule,
    DeviceCommandsModule,
    MaintenanceModule,
    NotificationsModule,
    SupportModule,
    AuditLogsModule,
    PortsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
