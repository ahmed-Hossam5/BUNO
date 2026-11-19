
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

import { DeviceCommandsService } from './device-commands.service.js';

import { CreateDeviceCommandDto } from './dto/create-device-command.dto.js';
import { FindDeviceCommandsQueryDto } from './dto/find-device-commands-query.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy.js';

import { ClientIp } from '../audit-logs/decorators/client-ip.decorator.js';

// ==========================================
// STAFF API
// Customers can never issue device commands directly;
// the rentals flow calls DeviceCommandsService instead.
// ==========================================

@Controller('device-commands')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'TECHNICIAN')
export class DeviceCommandsController {
  constructor(
    private readonly deviceCommandsService: DeviceCommandsService,
  ) {}

  // POST /device-commands
  @Post()
  create(
    @Body() dto: CreateDeviceCommandDto,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.deviceCommandsService.create(dto, {
      userId: user.userId,
      ip,
    });
  }

  // GET /device-commands
  @Get()
  findAll(@Query() query: FindDeviceCommandsQueryDto) {
    return this.deviceCommandsService.findAll(query);
  }

  // GET /device-commands/:id
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.deviceCommandsService.findOne(id);
  }

  // PATCH /device-commands/:id/cancel
  @Patch(':id/cancel')
  cancel(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @ClientIp() ip: string | null,
  ) {
    return this.deviceCommandsService.cancel(id, {
      userId: user.userId,
      ip,
    });
  }
}
