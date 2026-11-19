
import { Type } from 'class-transformer';

import {
  IsIn,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

import { auditActionEnum } from '../../../database/schema/audit-logs.schema.js';

export class FindAuditLogsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 20;

  // Who performed the action
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsIn([...auditActionEnum.enumValues], {
    message: `Action must be one of: ${auditActionEnum.enumValues.join(', ')}`,
  })
  action?: (typeof auditActionEnum.enumValues)[number];

  // What was affected
  @IsOptional()
  @IsString()
  @MaxLength(100)
  entityType?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  entityId?: string;

  // Time window (ISO 8601)
  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}
