
import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
} from '@nestjs/common';

import { PortsService } from './ports.service.js';
import { UpdatePortStatusDto } from './dto/update-port-status.dto.js';
@Controller()
export class PortsController {
  constructor(
    private readonly portsService: PortsService,
  ) {}

  // GET /ports
  @Get('ports')
  findAll() {
    return this.portsService.findAll();
  }

  // GET /ports/:id
  @Get('ports/:id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.portsService.findOne(id);
  }

  // GET /stations/:stationId/ports
  @Get('stations/:stationId/ports')
  findByStation(
    @Param('stationId', ParseUUIDPipe) stationId: string,
  ) {
    return this.portsService.findByStation(stationId);
  }


  // PATCH /ports/:id/status
  @Patch('ports/:id/status')
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePortStatusDto,
  ) {
    return this.portsService.updateStatus(id, dto);
  }

}
