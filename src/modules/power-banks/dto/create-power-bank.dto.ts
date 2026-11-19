import {
  IsNotEmpty,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreatePowerBankDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  deviceIdentifier!: string;
}