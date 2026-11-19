
import { IsIn } from 'class-validator';

import { portStatusEnum } from '../../../database/schema/ports.schema.js';

export class UpdatePortStatusDto {
  @IsIn([...portStatusEnum.enumValues], {
    message: `Status must be one of: ${portStatusEnum.enumValues.join(', ')}`,
  })
  status!: (typeof portStatusEnum.enumValues)[number];
}
