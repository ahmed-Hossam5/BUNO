
import {
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';

import { Interval } from '@nestjs/schedule';

import { DeviceCommandsService } from './device-commands.service.js';

// Periodically marks commands that were never completed
// within their TTL as TIMED_OUT.
// Requires ScheduleModule.forRoot() in AppModule.
@Injectable()
export class DeviceCommandsSweeper {
  private readonly logger = new Logger(
    DeviceCommandsSweeper.name,
  );

  private isRunning = false;

  constructor(
    @Inject(DeviceCommandsService)
    private readonly deviceCommandsService: DeviceCommandsService,
  ) {}

  @Interval(10_000)
  async expireStaleCommands() {
    // Prevent overlapping executions in this instance
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;

    try {
      const expired =
        await this.deviceCommandsService.expireStaleCommands();

      if (expired > 0) {
        this.logger.log(
          `Timed out ${expired} stale device command(s)`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Device command sweeper failed',
        error instanceof Error
          ? error.stack
          : String(error),
      );
    } finally {
      this.isRunning = false;
    }
  }
}
