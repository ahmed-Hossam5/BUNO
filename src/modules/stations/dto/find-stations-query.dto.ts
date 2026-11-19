
import { Type } from 'class-transformer';

import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class FindStationsQueryDto {
  // Pagination
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
  limit = 10;

  // Search by name or station code
  @IsOptional()
  @IsString()
  @MaxLength(150)
  search?: string;

  // Filter by station status
  @IsOptional()
  @IsIn(['ONLINE', 'OFFLINE', 'MAINTENANCE'])
  status?: 'ONLINE' | 'OFFLINE' | 'MAINTENANCE';
}
