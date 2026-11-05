import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module.js';
import { AdminPermissionGuard } from './admin-permission.guard.js';
import { AuditService } from './audit.service.js';

@Module({
  imports: [UsersModule],
  providers: [AdminPermissionGuard, AuditService],
  exports: [AdminPermissionGuard, AuditService, UsersModule],
})
export class RbacModule {}
