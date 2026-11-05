import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MediaService } from './media.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('MediaService', () => {
  let service: MediaService;
  let prisma: {
    media: { create: ReturnType<typeof vi.fn>; findMany: ReturnType<typeof vi.fn>; findUnique: ReturnType<typeof vi.fn>; delete: ReturnType<typeof vi.fn> };
  };

  beforeEach(async () => {
    prisma = { media: { create: vi.fn(), findMany: vi.fn(), findUnique: vi.fn(), delete: vi.fn() } };

    const module: TestingModule = await Test.createTestingModule({
      providers: [MediaService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<MediaService>(MediaService);
  });

  it('register stores the given metadata', async () => {
    const input = { filename: 'logo.png', url: 'https://example.com/logo.png', mimeType: 'image/png', sizeBytes: 1024 };
    prisma.media.create.mockResolvedValueOnce({ id: 'media-1', ...input });

    await expect(service.register(input)).resolves.toEqual({ id: 'media-1', ...input });
    expect(prisma.media.create).toHaveBeenCalledWith({ data: input });
  });

  it('remove throws when the media does not exist', async () => {
    prisma.media.findUnique.mockResolvedValueOnce(null);

    await expect(service.remove('missing')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.media.delete).not.toHaveBeenCalled();
  });

  it('remove deletes an existing media entry', async () => {
    prisma.media.findUnique.mockResolvedValueOnce({ id: 'media-1' });
    prisma.media.delete.mockResolvedValueOnce({ id: 'media-1' });

    await expect(service.remove('media-1')).resolves.toEqual({ id: 'media-1' });
  });
});
