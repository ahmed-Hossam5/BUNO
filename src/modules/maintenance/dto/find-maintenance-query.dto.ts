
import { Type } from 'class-transformer';

import {
  IsIn,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

import {
  maintenancePriorityEnum,
  maintenanceStatusEnum,
  maintenanceTargetTypeEnum,
  maintenanceTypeEnum,
} from '../../../database/schema/maintenance.schema.js';

export class FindMaintenanceQueryDto {
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

  @IsOptional()
  @IsIn([...maintenanceStatusEnum.enumValues])
  status?: (typeof maintenanceStatusEnum.enumValues)[number];

  @IsOptional()
  @IsIn([...maintenanceTargetTypeEnum.enumValues])
  targetType?: (typeof maintenanceTargetTypeEnum.enumValues)[number];

  // Maintenance history of one station / port / power bank
  @IsOptional()
  @IsUUID()
  targetId?: string;

  @IsOptional()
  @IsIn([...maintenanceTypeEnum.enumValues])
  maintenanceType?: (typeof maintenanceTypeEnum.enumValues)[number];

  @IsOptional()
  @IsIn([...maintenancePriorityEnum.enumValues])
  priority?: (typeof maintenancePriorityEnum.enumValues)[number];

  @IsOptional()
  @IsUUID()
  assignedTo?: string;
}
