
import { Type } from 'class-transformer';

import {
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

import { deviceCommandTypeEnum } from '../../../database/schema/device-commands.schema.js';

export class CreateDeviceCommandDto {
  @IsUUID()
  stationId!: string;

  @IsIn([...deviceCommandTypeEnum.enumValues], {
    message: `Command type must be one of: ${deviceCommandTypeEnum.enumValues.join(', ')}`,
  })
  commandType!: (typeof deviceCommandTypeEnum.enumValues)[number];

  // Required for port commands, forbidden for RESTART_STATION
  @IsOptional()
  @IsUUID()
  portId?: string;

  // How long the device may take to pick up / finish the command.
  // Default: 60s for RELEASE_POWER_BANK, 300s otherwise.
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(5)
  @Max(3600)
  ttlSeconds?: number;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
