
import { Transform } from 'class-transformer';

import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

import {
  maintenancePriorityEnum,
  maintenanceTargetTypeEnum,
  maintenanceTypeEnum,
} from '../../../database/schema/maintenance.schema.js';

export class CreateMaintenanceDto {
  @IsIn([...maintenanceTargetTypeEnum.enumValues], {
    message: `Target type must be one of: ${maintenanceTargetTypeEnum.enumValues.join(', ')}`,
  })
  targetType!: (typeof maintenanceTargetTypeEnum.enumValues)[number];

  // ID of the station, port or power bank (matches targetType)
  @IsUUID()
  targetId!: string;

  @IsIn([...maintenanceTypeEnum.enumValues])
  maintenanceType!: (typeof maintenanceTypeEnum.enumValues)[number];

  @IsOptional()
  @IsIn([...maintenancePriorityEnum.enumValues])
  priority?: (typeof maintenancePriorityEnum.enumValues)[number];

  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;
}
