import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { SupportService } from './support.service.js';
import { SupportController } from './support.controller.js';
import { AdminSupportController } from './admin-support.controller.js';

@Module({
  imports: [AuthModule, RbacModule],
  controllers: [SupportController, AdminSupportController],
  providers: [SupportService],
  exports: [SupportService],
})
export class SupportModule {}
