import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { NotificationsService } from './notifications.service.js';
import { SendNotificationDto } from './dto/send-notification.dto.js';

/** Journal d'envoi complet et nouvelle tentative contrôlée (§6.5). */
@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/notifications')
export class AdminNotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @RequirePermission('notifications', 'read')
  list() {
    return this.notificationsService.listAll();
  }

  @Post()
  @RequirePermission('notifications', 'create')
  send(@Body() dto: SendNotificationDto) {
    return this.notificationsService.send(dto);
  }

  @Post(':id/retry')
  @RequirePermission('notifications', 'update')
  retry(@Param('id') id: string) {
    return this.notificationsService.retry(id);
  }
}
