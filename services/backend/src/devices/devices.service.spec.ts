import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DevicesService } from './devices.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('DevicesService', () => {
  let service: DevicesService;
  let prisma: {
    device: {
      create: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = {
      device: { create: vi.fn(), findMany: vi.fn(), findUnique: vi.fn(), update: vi.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [DevicesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<DevicesService>(DevicesService);
  });

  describe('register', () => {
    it('creates a device owned by the given user', async () => {
      prisma.device.create.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-1', type: 'PHONE' });

      const result = await service.register('user-1', { type: 'PHONE', platform: 'ANDROID' });

      expect(result).toEqual({ id: 'device-1', ownerId: 'user-1', type: 'PHONE' });
      expect(prisma.device.create).toHaveBeenCalledWith({
        data: {
          ownerId: 'user-1',
          type: 'PHONE',
          platform: 'ANDROID',
          model: undefined,
          osVersion: undefined,
          appVersion: undefined,
          lastActiveAt: expect.any(Date),
        },
      });
    });
  });

  describe('findOneForOwner', () => {
    it('throws when the device does not exist', async () => {
      prisma.device.findUnique.mockResolvedValueOnce(null);

      await expect(service.findOneForOwner('device-1', 'user-1')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws when the device belongs to a different user', async () => {
      prisma.device.findUnique.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-2' });

      await expect(service.findOneForOwner('device-1', 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('returns the device when owned by the requester', async () => {
      const device = { id: 'device-1', ownerId: 'user-1' };
      prisma.device.findUnique.mockResolvedValueOnce(device);

      await expect(service.findOneForOwner('device-1', 'user-1')).resolves.toEqual(device);
    });
  });

  describe('heartbeat', () => {
    it('refuses to refresh a non-active device', async () => {
      prisma.device.findUnique.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-1', status: 'REVOKED' });

      await expect(service.heartbeat('device-1', 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.device.update).not.toHaveBeenCalled();
    });

    it('updates lastActiveAt for an active device', async () => {
      prisma.device.findUnique.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-1', status: 'ACTIVE' });
      prisma.device.update.mockResolvedValueOnce({ id: 'device-1', status: 'ACTIVE' });

      await expect(service.heartbeat('device-1', 'user-1')).resolves.toEqual({ id: 'device-1', status: 'ACTIVE' });
      expect(prisma.device.update).toHaveBeenCalledWith({
        where: { id: 'device-1' },
        data: { lastActiveAt: expect.any(Date) },
      });
    });
  });

  describe('revoke', () => {
    it('refuses to revoke a device owned by someone else', async () => {
      prisma.device.findUnique.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-2' });

      await expect(service.revoke('device-1', 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.device.update).not.toHaveBeenCalled();
    });

    it('sets status to REVOKED for the owner', async () => {
      prisma.device.findUnique.mockResolvedValueOnce({ id: 'device-1', ownerId: 'user-1', status: 'ACTIVE' });
      prisma.device.update.mockResolvedValueOnce({ id: 'device-1', status: 'REVOKED' });

      await expect(service.revoke('device-1', 'user-1')).resolves.toEqual({ id: 'device-1', status: 'REVOKED' });
      expect(prisma.device.update).toHaveBeenCalledWith({
        where: { id: 'device-1' },
        data: { status: 'REVOKED' },
      });
    });
  });
});
