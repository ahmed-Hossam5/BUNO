
import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
} from '@nestjs/common';

import { PortsService } from './ports.service.js';

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
}
