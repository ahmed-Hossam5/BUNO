
import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AuditLogsService } from './audit-logs.service.js';
import { FindAuditLogsQueryDto } from './dto/find-audit-logs-query.dto.js';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { RolesGuard } from '../auth/guards/roles.guard.js';
import { Roles } from '../auth/decorators/roles.decorator.js';

// Read-only by design: audit logs can be listed and viewed,
// never created, edited or deleted through the API.
@Controller('audit-logs')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AuditLogsController {
  constructor(
    private readonly auditLogsService: AuditLogsService,
  ) {}

  // GET /audit-logs
  @Get()
  findAll(@Query() query: FindAuditLogsQueryDto) {
    return this.auditLogsService.findAll(query);
  }

  // GET /audit-logs/:id
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.auditLogsService.findOne(id);
  }
}
