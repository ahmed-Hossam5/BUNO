import { Module } from '@nestjs/common';

import { DeviceCommandsController } from './device-commands.controller.js';
import { DeviceGatewayController } from './device-gateway.controller.js';
import { DeviceCommandsService } from './device-commands.service.js';
import { DeviceCommandsSweeper } from './device-commands.sweeper.js';
import { DeviceApiKeyGuard } from './guards/device-api-key.guard.js';

@Module({
  controllers: [
    DeviceCommandsController,
    DeviceGatewayController,
  ],
  providers: [
    DeviceCommandsService,
    DeviceCommandsSweeper,
    DeviceApiKeyGuard,
  ],
  // Exported so the rentals flow can issue commands
  exports: [DeviceCommandsService],
})
export class DeviceCommandsModule {}
