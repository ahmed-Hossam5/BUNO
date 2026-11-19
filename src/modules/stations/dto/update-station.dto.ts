
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  ValidateIf,
} from 'class-validator';

export class UpdateStationDto {
  @ValidateIf((_, value) => value !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  stationCode?: string;

  @ValidateIf((_, value) => value !== undefined)
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name?: string;
}
