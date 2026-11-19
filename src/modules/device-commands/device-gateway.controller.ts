
import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { DeviceCommandsService } from './device-commands.service.js';
import { DeviceApiKeyGuard } from './guards/device-api-key.guard.js';
import { ReportCommandResultDto } from './dto/report-command-result.dto.js';

// ==========================================
// DEVICE API (station firmware)
// Authenticated with the x-device-key header.
//
//   POST .../poll              fetch commands to execute
//   POST .../:commandId/ack    "I received it and started"
//   POST .../:commandId/result "done: success or failure"
// ==========================================

@Controller('device/stations/:stationId/commands')
@UseGuards(DeviceApiKeyGuard)
export class DeviceGatewayController {
  constructor(
    private readonly deviceCommandsService: DeviceCommandsService,
  ) {}

  @Post('poll')
  @HttpCode(HttpStatus.OK)
  poll(
    @Param('stationId', ParseUUIDPipe) stationId: string,
  ) {
    return this.deviceCommandsService.poll(stationId);
  }

  @Post(':commandId/ack')
  @HttpCode(HttpStatus.OK)
  acknowledge(
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Param('commandId', ParseUUIDPipe) commandId: string,
  ) {
    return this.deviceCommandsService.acknowledge(
      stationId,
      commandId,
    );
  }

  @Post(':commandId/result')
  @HttpCode(HttpStatus.OK)
  reportResult(
    @Param('stationId', ParseUUIDPipe) stationId: string,
    @Param('commandId', ParseUUIDPipe) commandId: string,
    @Body() dto: ReportCommandResultDto,
  ) {
    return this.deviceCommandsService.reportResult(
      stationId,
      commandId,
      dto,
    );
  }
}
