import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UsersService } from './users.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: {
    user: {
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = { user: { findUnique: vi.fn(), create: vi.fn() } };

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
});
