import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { HealthService } from './health.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('HealthService', () => {
  let service: HealthService;
  let prisma: { $queryRaw: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    prisma = { $queryRaw: vi.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [HealthService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<HealthService>(HealthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('returns ok when the database query succeeds', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ '?column?': 1 }]);

    await expect(service.checkDatabase()).resolves.toEqual({ status: 'ok' });
  });

  it('returns error with the failure message when the query throws', async () => {
    prisma.$queryRaw.mockRejectedValueOnce(new Error('connection refused'));

    await expect(service.checkDatabase()).resolves.toEqual({
      status: 'error',
      error: 'connection refused',
    });
  });
});
