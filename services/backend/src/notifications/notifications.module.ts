import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { UsersModule } from '../users/users.module.js';
import { NotificationsService } from './notifications.service.js';
import { NotificationsController } from './notifications.controller.js';
import { AdminNotificationsController } from './admin-notifications.controller.js';
import { LogNotificationTransport } from './notification-transport.js';
import { NOTIFICATION_TRANSPORT } from './notification-transport.token.js';

@Module({
  imports: [AuthModule, RbacModule, UsersModule],
  controllers: [NotificationsController, AdminNotificationsController],
  providers: [NotificationsService, { provide: NOTIFICATION_TRANSPORT, useClass: LogNotificationTransport }],
  exports: [NotificationsService],
})
export class NotificationsModule {}
