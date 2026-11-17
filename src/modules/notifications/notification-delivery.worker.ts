
import {
  Injectable,
  Logger,
} from '@nestjs/common';

import {
  Interval,
} from '@nestjs/schedule';

import {
  NotificationsService,
} from './notifications.service.js';

@Injectable()
export class NotificationDeliveryWorker {
  private readonly logger = new Logger(
    NotificationDeliveryWorker.name,
  );

  private isRunning = false;

  constructor(
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==========================================
  // PROCESS PENDING NOTIFICATIONS
  // ==========================================

  @Interval(5000)
  async processPendingNotifications() {
    // Prevent overlapping executions
    // inside the same application instance.

    if (this.isRunning) {
      return;
    }

    this.isRunning = true;

    try {
      const result =
        await this.notificationsService
          .processPendingDeliveries(25);

      if (result.claimed > 0) {
        this.logger.log(
          `Notification Worker: ${JSON.stringify(result)}`,
        );
      }

    } catch (error) {
      this.logger.error(
        'Notification Worker execution failed',
        error instanceof Error
          ? error.stack
          : String(error),
      );

    } finally {
      this.isRunning = false;
    }
  }
}
