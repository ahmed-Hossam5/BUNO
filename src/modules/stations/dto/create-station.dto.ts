
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsInt,
  Min,
  Max,
  ValidateIf,
} from 'class-validator';

import { Type, Transform } from 'class-transformer';

export class CreateStationDto {
  // Station Code
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value
  )
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  stationCode!: string;

  // Station Name
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : value
  )
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name!: string;

  // Total Ports (Optional: Default = 4)
  @ValidateIf((_, value) => value !== undefined)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(16)
  totalPorts?: number;
}
