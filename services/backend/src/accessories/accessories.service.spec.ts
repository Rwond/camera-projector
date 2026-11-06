import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AccessoriesService } from './accessories.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('AccessoriesService', () => {
  let service: AccessoriesService;
  let prisma: {
    accessory: {
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = {
      accessory: { findUnique: vi.fn(), create: vi.fn(), update: vi.fn(), findMany: vi.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [AccessoriesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<AccessoriesService>(AccessoriesService);
  });

  describe('registerCatalogEntry', () => {
    it('rejects a duplicate serial number', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce({ id: 'acc-1' });

      await expect(
        service.registerCatalogEntry({ serialNumber: 'SN-1', model: 'SWVERTEX Mini' }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.accessory.create).not.toHaveBeenCalled();
    });

    it('creates the catalog entry for a new serial number', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce(null);
      prisma.accessory.create.mockResolvedValueOnce({ id: 'acc-1', serialNumber: 'SN-1' });

      await expect(
        service.registerCatalogEntry({ serialNumber: 'SN-1', model: 'SWVERTEX Mini' }),
      ).resolves.toEqual({ id: 'acc-1', serialNumber: 'SN-1' });
    });
  });

  describe('claim', () => {
    it('rejects an unknown serial number', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce(null);

      await expect(service.claim('user-1', 'SN-missing')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects an accessory already owned by someone', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce({ id: 'acc-1', ownerId: 'user-2' });

      await expect(service.claim('user-1', 'SN-1')).rejects.toBeInstanceOf(ConflictException);
    });

    it('assigns ownership for an unclaimed accessory', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce({ id: 'acc-1', ownerId: null });
      prisma.accessory.update.mockResolvedValueOnce({ id: 'acc-1', ownerId: 'user-1', saleStatus: 'SOLD' });

      await expect(service.claim('user-1', 'SN-1')).resolves.toEqual({
        id: 'acc-1',
        ownerId: 'user-1',
        saleStatus: 'SOLD',
      });
      expect(prisma.accessory.update).toHaveBeenCalledWith({
        where: { id: 'acc-1' },
        data: { ownerId: 'user-1', saleStatus: 'SOLD' },
      });
    });
  });

  describe('listAll', () => {
    it('returns every catalog entry ordered by most recent', async () => {
      prisma.accessory.findMany.mockResolvedValueOnce([]);

      await service.listAll();

      expect(prisma.accessory.findMany).toHaveBeenCalledWith({ orderBy: { createdAt: 'desc' } });
    });
  });

  describe('release', () => {
    it('rejects releasing an accessory owned by someone else', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce({ id: 'acc-1', ownerId: 'user-2' });

      await expect(service.release('acc-1', 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('clears ownership for the current owner', async () => {
      prisma.accessory.findUnique.mockResolvedValueOnce({ id: 'acc-1', ownerId: 'user-1' });
      prisma.accessory.update.mockResolvedValueOnce({ id: 'acc-1', ownerId: null });

      await expect(service.release('acc-1', 'user-1')).resolves.toEqual({ id: 'acc-1', ownerId: null });
    });
  });
});
