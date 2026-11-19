import { Global, Module } from '@nestjs/common';

import { AuditLogsController } from './audit-logs.controller.js';
import { AuditLogsService } from './audit-logs.service.js';

// Global so any module can inject AuditLogsService
// without importing AuditLogsModule explicitly.
@Global()
@Module({
  controllers: [AuditLogsController],
  providers: [AuditLogsService],
  exports: [AuditLogsService],
})
export class AuditLogsModule {}
