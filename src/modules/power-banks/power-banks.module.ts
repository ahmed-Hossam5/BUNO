
import { Module } from '@nestjs/common';

import { PowerBanksController } from './power-banks.controller.js';
import { PowerBanksService } from './power-banks.service.js';

@Module({
  controllers: [PowerBanksController],
  providers: [PowerBanksService],
  exports: [PowerBanksService],
})
export class PowerBanksModule {}
