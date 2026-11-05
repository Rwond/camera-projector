import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { CompatibilityService } from './compatibility.service.js';
import { CompatibilityController } from './compatibility.controller.js';
import { AdminCompatibilityController } from './admin-compatibility.controller.js';

@Module({
  imports: [AuthModule, RbacModule],
  controllers: [CompatibilityController, AdminCompatibilityController],
  providers: [CompatibilityService],
  exports: [CompatibilityService],
})
export class CompatibilityModule {}
