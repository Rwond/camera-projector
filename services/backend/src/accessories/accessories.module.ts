import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { AccessoriesService } from './accessories.service.js';
import { AccessoriesController } from './accessories.controller.js';
import { AdminAccessoriesController } from './admin-accessories.controller.js';

@Module({
  imports: [AuthModule, RbacModule],
  controllers: [AccessoriesController, AdminAccessoriesController],
  providers: [AccessoriesService],
  exports: [AccessoriesService],
})
export class AccessoriesModule {}
