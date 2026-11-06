import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { AccessoriesService } from './accessories.service.js';
import { CreateCatalogEntryDto } from './dto/create-catalog-entry.dto.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/accessories')
export class AdminAccessoriesController {
  constructor(
    private readonly accessoriesService: AccessoriesService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  @RequirePermission('accessories', 'read')
  list() {
    return this.accessoriesService.listAll();
  }

  @Post()
  @RequirePermission('accessories', 'create')
  async create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCatalogEntryDto) {
    const accessory = await this.accessoriesService.registerCatalogEntry({
      serialNumber: dto.serialNumber,
      model: dto.model,
      firmwareVersion: dto.firmwareVersion,
      batchNumber: dto.batchNumber,
      warrantyExpiresAt: dto.warrantyExpiresAt ? new Date(dto.warrantyExpiresAt) : undefined,
    });

    await this.auditService.log({
      actorId: user.id,
      action: 'accessory.catalog.create',
      targetType: 'Accessory',
      targetId: accessory.id,
      result: 'SUCCESS',
      metadata: { serialNumber: accessory.serialNumber },
    });

    return accessory;
  }
}
