import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UsersService } from './users.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: {
    user: {
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = { user: { findUnique: vi.fn(), create: vi.fn(), update: vi.fn(), findMany: vi.fn() } };

    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('findByEmail queries the user table by email', async () => {
    const user = { id: '1', email: 'a@b.com' };
    prisma.user.findUnique.mockResolvedValueOnce(user);

    await expect(service.findByEmail('a@b.com')).resolves.toEqual(user);
    expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'a@b.com' } });
  });

  it('createWithPasswordHash creates a user with the given email and hash', async () => {
    const user = { id: '1', email: 'a@b.com', passwordHash: 'hashed' };
    prisma.user.create.mockResolvedValueOnce(user);

    await expect(service.createWithPasswordHash('a@b.com', 'hashed')).resolves.toEqual(user);
    expect(prisma.user.create).toHaveBeenCalledWith({
      data: { email: 'a@b.com', passwordHash: 'hashed' },
    });
  });

  describe('setAdminRole', () => {
    it('throws when the user does not exist', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await expect(service.setAdminRole('user-1', 'SUPPORT_AGENT')).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.user.update).not.toHaveBeenCalled();
    });

    it('updates the admin role for an existing user', async () => {
      prisma.user.findUnique.mockResolvedValueOnce({ id: 'user-1', email: 'a@b.com' });
      prisma.user.update.mockResolvedValueOnce({ id: 'user-1', adminRole: 'SUPPORT_AGENT' });

      await expect(service.setAdminRole('user-1', 'SUPPORT_AGENT')).resolves.toEqual({
        id: 'user-1',
        adminRole: 'SUPPORT_AGENT',
      });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { adminRole: 'SUPPORT_AGENT' },
      });
    });
  });

  describe('search', () => {
    it('filters by email when a query is given', async () => {
      prisma.user.findMany.mockResolvedValueOnce([]);

      await service.search('alice');

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: { email: { contains: 'alice', mode: 'insensitive' } },
        orderBy: { createdAt: 'desc' },
        take: 25,
      });
    });

    it('returns the most recent accounts when no query is given', async () => {
      prisma.user.findMany.mockResolvedValueOnce([]);

      await service.search();

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: undefined,
        orderBy: { createdAt: 'desc' },
        take: 25,
      });
    });
  });
});
