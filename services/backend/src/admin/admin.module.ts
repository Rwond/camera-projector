import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { UsersModule } from '../users/users.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { AdminUsersController } from './admin-users.controller.js';
import { AdminAuditController } from './admin-audit.controller.js';

@Module({
  imports: [AuthModule, UsersModule, RbacModule],
  controllers: [AdminUsersController, AdminAuditController],
})
export class AdminModule {}
