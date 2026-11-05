import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { AccessoriesService } from './accessories.service.js';
import { AccessoriesController } from './accessories.controller.js';

@Module({
  imports: [AuthModule],
  controllers: [AccessoriesController],
  providers: [AccessoriesService],
  exports: [AccessoriesService],
})
export class AccessoriesModule {}
