import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';
import type { Notification, NotificationChannel, Prisma } from '../generated/prisma/client.js';
import { NOTIFICATION_TRANSPORT, type NotificationTransport } from './notification-transport.token.js';

export interface SendNotificationInput {
  userId: string;
  channel: NotificationChannel;
  template: string;
  payload?: Record<string, unknown>;
}

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
    @Inject(NOTIFICATION_TRANSPORT) private readonly transport: NotificationTransport,
  ) {}

  async send(input: SendNotificationInput): Promise<Notification> {
    const recipient = await this.usersService.findById(input.userId);
    if (!recipient) {
      throw new NotFoundException('Destinataire introuvable.');
    }

    const notification = await this.prisma.notification.create({
      data: { ...input, payload: input.payload as Prisma.InputJsonValue | undefined, attempts: 1 },
    });

    const success = await this.transport.dispatch(notification);
    return this.prisma.notification.update({
      where: { id: notification.id },
      data: success
        ? { status: 'SENT', sentAt: new Date() }
        : { status: 'FAILED', error: 'Échec du transport de notification.' },
    });
  }

  async retry(id: string): Promise<Notification> {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundException('Notification introuvable.');
    }

    const success = await this.transport.dispatch(notification);
    return this.prisma.notification.update({
      where: { id },
      data: success
        ? { status: 'SENT', sentAt: new Date(), attempts: { increment: 1 }, error: null }
        : { status: 'FAILED', attempts: { increment: 1 } },
    });
  }

  listForUser(userId: string): Promise<Notification[]> {
    return this.prisma.notification.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
  }

  listAll(): Promise<Notification[]> {
    return this.prisma.notification.findMany({ orderBy: { createdAt: 'desc' }, take: 100 });
  }
}
