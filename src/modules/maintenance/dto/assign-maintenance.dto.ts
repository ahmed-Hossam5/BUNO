
import { IsUUID } from 'class-validator';

export class AssignMaintenanceDto {
  @IsUUID()
  assignedTo!: string;
}
