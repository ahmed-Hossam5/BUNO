
import {
  IsUUID,
} from 'class-validator';

export class PlacePowerBankDto {
  @IsUUID()
  portId!: string;
}
