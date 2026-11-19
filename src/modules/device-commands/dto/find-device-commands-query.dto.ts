
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
  deviceCommandStatusEnum,
  deviceCommandTypeEnum,
} from '../../../database/schema/device-commands.schema.js';

export class FindDeviceCommandsQueryDto {
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
  @IsUUID()
  stationId?: string;

  @IsOptional()
  @IsUUID()
  portId?: string;

  @IsOptional()
  @IsIn([...deviceCommandStatusEnum.enumValues])
  status?: (typeof deviceCommandStatusEnum.enumValues)[number];

  @IsOptional()
  @IsIn([...deviceCommandTypeEnum.enumValues])
  commandType?: (typeof deviceCommandTypeEnum.enumValues)[number];
}
