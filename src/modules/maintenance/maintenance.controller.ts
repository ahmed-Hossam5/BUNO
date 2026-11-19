
import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { MaintenanceService } from './maintenance.service.js';

import { CreateMaintenanceDto } from './dto/create-maintenance.dto.js';
import { CompleteMaintenanceDto } from './dto/complete-maintenance.dto.js';
import { CancelMaintenanceDto } from './dto/cancel-maintenance.dto.js';
import { AssignMaintenanceDto } from './dto/assign-maintenance.dto.js';
import { FindMaintenanceQueryDto } from './dto/find-maintenance-query.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy.js';

import { ClientIp } from '../audit-logs/decorators/client-ip.decorator.js';

@Controller('maintenance')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('TECHNICIAN', 'ADMIN')
export class MaintenanceController {
  constructor(
    private readonly maintenanceService: MaintenanceService,
  ) {}

  private actor(
    user: AuthenticatedUser,
    ip: string | null,
  ) {
    return { userId: user.userId, role: user.role, ip };
  }

  // POST /maintenance
  @Post()
  create(
    @Body() dto: CreateMaintenanceDto,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.maintenanceService.create(
      dto,
      this.actor(user, ip),
    );
  }

  // GET /maintenance
  @Get()
  findAll(@Query() query: FindMaintenanceQueryDto) {
    return this.maintenanceService.findAll(query);
  }

  // GET /maintenance/:id
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.maintenanceService.findOne(id);
  }

  // PATCH /maintenance/:id/start
  @Patch(':id/start')
  start(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.maintenanceService.start(
      id,
      this.actor(user, ip),
    );
  }

  // PATCH /maintenance/:id/complete
  @Patch(':id/complete')
  complete(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CompleteMaintenanceDto,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.maintenanceService.complete(
      id,
      dto,
      this.actor(user, ip),
    );
  }

  // PATCH /maintenance/:id/cancel
  @Patch(':id/cancel')
  cancel(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelMaintenanceDto,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.maintenanceService.cancel(
      id,
      dto,
      this.actor(user, ip),
    );
  }

  // PATCH /maintenance/:id/assign  (administrators only)
  @Patch(':id/assign')
  @Roles('ADMIN')
  assign(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignMaintenanceDto,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.maintenanceService.assign(
      id,
      dto,
      this.actor(user, ip),
    );
  }
}
