
import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Param,
  ParseUUIDPipe,
} from '@nestjs/common';

import { PowerBanksService } from './power-banks.service.js';

import { CreatePowerBankDto } from './dto/create-power-bank.dto.js';
import { PlacePowerBankDto } from './dto/place-power-bank.dto.js';

@Controller()
export class PowerBanksController {
  constructor(
    private readonly powerBanksService: PowerBanksService,
  ) {}

  // ==========================================
  // POST /power-banks
  // Create Power Bank
  // ==========================================

  @Post('power-banks')
  create(@Body() dto: CreatePowerBankDto) {
    return this.powerBanksService.create(dto);
  }

  // ==========================================
  // GET /power-banks
  // Get All Power Banks
  // ==========================================

  @Get('power-banks')
  findAll() {
    return this.powerBanksService.findAll();
  }

  // ==========================================
  // GET /power-banks/:id/movements
  // Get Power Bank Movement History
  // ==========================================

  @Get('power-banks/:id/movements')
  findMovements(
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.powerBanksService.findMovements(id);
  }

  // ==========================================
  // PATCH /power-banks/:id/place
  // Initial Placement
  // ==========================================

  @Patch('power-banks/:id/place')
  place(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PlacePowerBankDto,
  ) {
    return this.powerBanksService.place(id, dto);
  }

  // ==========================================
  // GET /power-banks/:id
  // Get Power Bank By ID
  // ==========================================

  @Get('power-banks/:id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.powerBanksService.findOne(id);
  }

  // ==========================================
  // GET /stations/:stationId/power-banks
  // Get Power Banks By Station
  // ==========================================

  @Get('stations/:stationId/power-banks')
  findByStation(
    @Param('stationId', ParseUUIDPipe)
    stationId: string,
  ) {
    return this.powerBanksService.findByStation(stationId);
  }
}
