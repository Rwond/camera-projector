import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { SupportService } from './support.service.js';
import { AddStaffMessageDto } from './dto/add-staff-message.dto.js';
import { UpdateTicketDto } from './dto/update-ticket.dto.js';
import type { TicketCategory, TicketStatus } from '../generated/prisma/client.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/support/tickets')
export class AdminSupportController {
  constructor(
    private readonly supportService: SupportService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  @RequirePermission('support', 'read')
  list(@Query('status') status?: TicketStatus, @Query('category') category?: TicketCategory) {
    return this.supportService.listForStaff({ status, category });
  }

  @Get(':id')
  @RequirePermission('support', 'read')
  findOne(@Param('id') id: string) {
    return this.supportService.getForStaff(id);
  }

  @Post(':id/messages')
  @RequirePermission('support', 'create')
  addMessage(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() dto: AddStaffMessageDto) {
    return this.supportService.addMessageAsStaff(id, user.id, dto.body, dto.isInternalNote ?? false);
  }

  @Patch(':id')
  @RequirePermission('support', 'update')
  async update(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() dto: UpdateTicketDto) {
    const ticket = await this.supportService.update(id, dto);
    await this.auditService.log({
      actorId: user.id,
      action: 'support.ticket.update',
      targetType: 'SupportTicket',
      targetId: ticket.id,
      result: 'SUCCESS',
      metadata: { ...dto },
    });
    return ticket;
  }
}
