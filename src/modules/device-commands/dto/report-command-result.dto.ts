
import {
  IsBoolean,
  IsObject,
  IsOptional,
} from 'class-validator';

// Sent by the station firmware when a command finished.
export class ReportCommandResultDto {
  @IsBoolean()
  success!: boolean;

  // Optional device details (error code, measurements, ...)
  @IsOptional()
  @IsObject()
  response?: Record<string, unknown>;
}
