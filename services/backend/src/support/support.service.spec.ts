import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SupportService } from './support.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('SupportService', () => {
  let service: SupportService;
  let prisma: {
    supportTicket: {
      create: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
    supportMessage: { create: ReturnType<typeof vi.fn>; findMany: ReturnType<typeof vi.fn> };
  };

  beforeEach(async () => {
    prisma = {
      supportTicket: { create: vi.fn(), findMany: vi.fn(), findUnique: vi.fn(), update: vi.fn() },
      supportMessage: { create: vi.fn(), findMany: vi.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [SupportService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<SupportService>(SupportService);
  });

  it('createTicket nests the first message under the new ticket', async () => {
    prisma.supportTicket.create.mockResolvedValueOnce({ id: 'ticket-1', messages: [{ id: 'm1' }] });

    await service.createTicket('user-1', 'ACCOUNT', 'Je ne peux pas me connecter.');

    expect(prisma.supportTicket.create).toHaveBeenCalledWith({
      data: {
        requesterId: 'user-1',
        category: 'ACCOUNT',
        messages: { create: { authorId: 'user-1', body: 'Je ne peux pas me connecter.' } },
      },
      include: { messages: true },
    });
  });

  describe('getForUser', () => {
    it('rejects a ticket owned by someone else', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({ id: 'ticket-1', requesterId: 'user-2' });

      await expect(service.getForUser('ticket-1', 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws for an unknown ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce(null);

      await expect(service.getForUser('missing', 'user-1')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('hides internal notes from the requester', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({ id: 'ticket-1', requesterId: 'user-1' });
      prisma.supportMessage.findMany.mockResolvedValueOnce([{ id: 'm1', isInternalNote: false }]);

      await service.getForUser('ticket-1', 'user-1');

      expect(prisma.supportMessage.findMany).toHaveBeenCalledWith({
        where: { ticketId: 'ticket-1', isInternalNote: false },
        orderBy: { createdAt: 'asc' },
      });
    });
  });

  describe('addMessageAsRequester', () => {
    it('rejects messages on a closed ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({
        id: 'ticket-1',
        requesterId: 'user-1',
        status: 'CLOSED',
      });

      await expect(service.addMessageAsRequester('ticket-1', 'user-1', 'Toujours un souci')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('rejects a non-owner', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({
        id: 'ticket-1',
        requesterId: 'user-2',
        status: 'OPEN',
      });

      await expect(service.addMessageAsRequester('ticket-1', 'user-1', 'x')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('creates the message for the owner on an open ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({
        id: 'ticket-1',
        requesterId: 'user-1',
        status: 'OPEN',
      });
      prisma.supportMessage.create.mockResolvedValueOnce({ id: 'm2' });

      await expect(service.addMessageAsRequester('ticket-1', 'user-1', 'Merci')).resolves.toEqual({ id: 'm2' });
    });
  });

  describe('update', () => {
    it('throws for an unknown ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce(null);

      await expect(service.update('missing', { status: 'RESOLVED' })).rejects.toBeInstanceOf(NotFoundException);
    });

    it('updates an existing ticket', async () => {
      prisma.supportTicket.findUnique.mockResolvedValueOnce({ id: 'ticket-1' });
      prisma.supportTicket.update.mockResolvedValueOnce({ id: 'ticket-1', status: 'RESOLVED' });

      await expect(service.update('ticket-1', { status: 'RESOLVED' })).resolves.toEqual({
        id: 'ticket-1',
        status: 'RESOLVED',
      });
    });
  });
});
