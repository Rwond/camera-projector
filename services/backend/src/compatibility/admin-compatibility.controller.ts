import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { CompatibilityService } from './compatibility.service.js';
import { CreateCompatibilityRecordDto } from './dto/create-compatibility-record.dto.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/compatibility')
export class AdminCompatibilityController {
  constructor(
    private readonly compatibilityService: CompatibilityService,
    private readonly auditService: AuditService,
  ) {}

  @Post()
  @RequirePermission('compatibility', 'create')
  async create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCompatibilityRecordDto) {
    const record = await this.compatibilityService.createRecord({
      ...dto,
      testedAt: dto.testedAt ? new Date(dto.testedAt) : undefined,
    });

    await this.auditService.log({
      actorId: user.id,
      action: 'compatibility.record.create',
      targetType: 'CompatibilityRecord',
      targetId: record.id,
      result: 'SUCCESS',
      metadata: { deviceModel: record.deviceModel, mode: record.mode, result: record.result },
    });

    return record;
  }
}
