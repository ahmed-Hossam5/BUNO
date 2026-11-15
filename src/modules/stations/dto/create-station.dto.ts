
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsInt,
  Min,
  ValidateIf,
} from 'class-validator';

import { Type } from 'class-transformer';

export class CreateStationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  stationCode!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name!: string;

  @ValidateIf((_, value) => value !== undefined)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  totalPorts?: number;
}
