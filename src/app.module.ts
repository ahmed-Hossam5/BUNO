import { Module } from '@nestjs/common';
import { createObserveModule } from '@nestjs/observe';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
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

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    // Distributed tracing, auto-correlated logs, request/job metrics, error
    // telemetry, alarms, and more — out of the box. Sign up at https://observe.nestjs.com
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
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
