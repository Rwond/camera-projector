import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NotificationsService } from './notifications.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';
import { NOTIFICATION_TRANSPORT } from './notification-transport.token.js';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: {
    notification: {
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
    };
  };
  let usersService: { findById: ReturnType<typeof vi.fn> };
  let transport: { dispatch: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    prisma = {
      notification: { create: vi.fn(), update: vi.fn(), findUnique: vi.fn(), findMany: vi.fn() },
    };
    usersService = { findById: vi.fn() };
    transport = { dispatch: vi.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: UsersService, useValue: usersService },
        { provide: NOTIFICATION_TRANSPORT, useValue: transport },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
  });

  describe('send', () => {
    it('rejects an unknown recipient', async () => {
      usersService.findById.mockResolvedValueOnce(null);

      await expect(
        service.send({ userId: 'user-1', channel: 'EMAIL', template: 'welcome' }),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.notification.create).not.toHaveBeenCalled();
    });

    it('marks the notification SENT when the transport succeeds', async () => {
      usersService.findById.mockResolvedValueOnce({ id: 'user-1' });
      prisma.notification.create.mockResolvedValueOnce({ id: 'notif-1' });
      transport.dispatch.mockResolvedValueOnce(true);
      prisma.notification.update.mockResolvedValueOnce({ id: 'notif-1', status: 'SENT' });

      await expect(service.send({ userId: 'user-1', channel: 'EMAIL', template: 'welcome' })).resolves.toEqual({
        id: 'notif-1',
        status: 'SENT',
      });
      expect(prisma.notification.update).toHaveBeenCalledWith({
        where: { id: 'notif-1' },
        data: { status: 'SENT', sentAt: expect.any(Date) },
      });
    });

    it('marks the notification FAILED when the transport fails', async () => {
      usersService.findById.mockResolvedValueOnce({ id: 'user-1' });
      prisma.notification.create.mockResolvedValueOnce({ id: 'notif-1' });
      transport.dispatch.mockResolvedValueOnce(false);
      prisma.notification.update.mockResolvedValueOnce({ id: 'notif-1', status: 'FAILED' });

      await service.send({ userId: 'user-1', channel: 'EMAIL', template: 'welcome' });

      expect(prisma.notification.update).toHaveBeenCalledWith({
        where: { id: 'notif-1' },
        data: { status: 'FAILED', error: 'Échec du transport de notification.' },
      });
    });
  });

  describe('retry', () => {
    it('throws when the notification does not exist', async () => {
      prisma.notification.findUnique.mockResolvedValueOnce(null);

      await expect(service.retry('missing')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('increments attempts and clears the error on success', async () => {
      prisma.notification.findUnique.mockResolvedValueOnce({ id: 'notif-1' });
      transport.dispatch.mockResolvedValueOnce(true);
      prisma.notification.update.mockResolvedValueOnce({ id: 'notif-1', status: 'SENT' });

      await service.retry('notif-1');

      expect(prisma.notification.update).toHaveBeenCalledWith({
        where: { id: 'notif-1' },
        data: { status: 'SENT', sentAt: expect.any(Date), attempts: { increment: 1 }, error: null },
      });
    });
  });
});
