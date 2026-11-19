
import {
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CancelMaintenanceDto {
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;
}
