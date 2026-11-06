import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { UsersService } from '../users/users.service.js';
import { UpdateAdminRoleDto } from './dto/update-admin-role.dto.js';

/**
 * Seul SUPER_ADMIN possède la permission users:approve dans la matrice RBAC (§8) — c'est donc le
 * seul rôle qui peut accorder ou retirer un rôle d'administration à un autre compte.
 */
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/users')
export class AdminUsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  @RequirePermission('users', 'read')
  async search(@Query('email') email?: string) {
    const users = await this.usersService.search(email);
    return users.map((user) => ({
      id: user.id,
      email: user.email,
      status: user.status,
      adminRole: user.adminRole,
      createdAt: user.createdAt,
    }));
  }

  @Patch(':id/admin-role')
  @RequirePermission('users', 'approve')
  async updateAdminRole(
    @CurrentUser() actor: AuthenticatedUser,
    @Param('id') targetUserId: string,
    @Body() dto: UpdateAdminRoleDto,
  ) {
    const updated = await this.usersService.setAdminRole(targetUserId, dto.adminRole ?? null);

    await this.auditService.log({
      actorId: actor.id,
      action: 'user.adminRole.update',
      targetType: 'User',
      targetId: targetUserId,
      result: 'SUCCESS',
      metadata: { adminRole: dto.adminRole ?? null },
    });

    return { id: updated.id, email: updated.email, adminRole: updated.adminRole };
  }
}
