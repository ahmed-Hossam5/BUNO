
import { Transform } from 'class-transformer';

import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CompleteMaintenanceDto {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  resolutionNotes!: string;

  // POWER_BANK only: empty port to put the Power Bank back into.
  // If omitted the Power Bank returns to stock (AVAILABLE, no port).
  @IsOptional()
  @IsUUID()
  returnPortId?: string;

  // STATION only: status after the work.
  // Default: the status the station had before maintenance.
  @IsOptional()
  @IsIn(['ONLINE', 'OFFLINE'])
  stationStatusAfter?: 'ONLINE' | 'OFFLINE';
}
