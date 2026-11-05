import { Module } from '@nestjs/common';
import { CompatibilityService } from './compatibility.service.js';
import { CompatibilityController } from './compatibility.controller.js';

@Module({
  controllers: [CompatibilityController],
  providers: [CompatibilityService],
  exports: [CompatibilityService],
})
export class CompatibilityModule {}
