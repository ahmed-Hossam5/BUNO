
import {
  Body,
  Controller,
  Get,
  Post,
  Patch,
  Param,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';

import { StationsService } from './stations.service.js';

import { CreateStationDto } from './dto/create-station.dto.js';
import { UpdateStationDto } from './dto/update-station.dto.js';
import { FindStationsQueryDto } from './dto/find-stations-query.dto.js';

@Controller('stations')
export class StationsController {
  constructor(
    private readonly stationsService: StationsService,
  ) {}

  // POST /stations
  @Post()
  create(@Body() dto: CreateStationDto) {
    return this.stationsService.create(dto);
  }

  // GET /stations
  @Get()
  findAll(
    @Query() query: FindStationsQueryDto,
  ) {
    return this.stationsService.findAll(query);
  }

  // GET /stations/:id
  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.stationsService.findOne(id);
  }

  // PATCH /stations/:id
  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStationDto,
  ) {
    return this.stationsService.update(id, dto);
  }
}
