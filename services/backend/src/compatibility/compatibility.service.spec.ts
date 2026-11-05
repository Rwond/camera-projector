import { Test, TestingModule } from '@nestjs/testing';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CompatibilityService } from './compatibility.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('CompatibilityService', () => {
  let service: CompatibilityService;
  let prisma: {
    compatibilityRecord: { create: ReturnType<typeof vi.fn>; findMany: ReturnType<typeof vi.fn> };
  };

  beforeEach(async () => {
    prisma = { compatibilityRecord: { create: vi.fn(), findMany: vi.fn() } };

    const module: TestingModule = await Test.createTestingModule({
      providers: [CompatibilityService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<CompatibilityService>(CompatibilityService);
  });

  it('createRecord stores the given data as-is', async () => {
    const input = {
      deviceModel: 'Pixel 9',
      osName: 'Android',
      mode: 'MODE_B_WIRELESS' as const,
      feature: 'pairing',
    };
    prisma.compatibilityRecord.create.mockResolvedValueOnce({ id: 'rec-1', ...input });

    await expect(service.createRecord(input)).resolves.toEqual({ id: 'rec-1', ...input });
    expect(prisma.compatibilityRecord.create).toHaveBeenCalledWith({ data: input });
  });

  it('query applies only the filters that were provided', async () => {
    prisma.compatibilityRecord.findMany.mockResolvedValueOnce([]);

    await service.query({ deviceModel: 'Pixel 9' });

    expect(prisma.compatibilityRecord.findMany).toHaveBeenCalledWith({
      where: { deviceModel: 'Pixel 9' },
      orderBy: { testedAt: 'desc' },
    });
  });

  it('query returns everything when no filter is provided', async () => {
    prisma.compatibilityRecord.findMany.mockResolvedValueOnce([]);

    await service.query({});

    expect(prisma.compatibilityRecord.findMany).toHaveBeenCalledWith({
      where: {},
      orderBy: { testedAt: 'desc' },
    });
  });
});
