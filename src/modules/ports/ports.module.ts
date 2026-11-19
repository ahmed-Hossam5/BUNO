
import { Module } from '@nestjs/common';

import { PortsController } from './ports.controller.js';
import { PortsService } from './ports.service.js';

@Module({
  controllers: [PortsController],
  providers: [PortsService],
})
export class PortsModule {}
