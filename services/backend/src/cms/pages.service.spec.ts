import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PagesService } from './pages.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('PagesService', () => {
  let service: PagesService;
  let prisma: {
    cmsPage: {
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      delete: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = {
      cmsPage: {
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
        findMany: vi.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [PagesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<PagesService>(PagesService);
  });

  describe('createDraft', () => {
    it('rejects a duplicate slug/locale', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce({ id: 'page-1' });

      await expect(
        service.createDraft('author-1', { slug: 'accueil', locale: 'fr', title: 'Accueil', blocks: {} }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('creates the draft otherwise', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce(null);
      prisma.cmsPage.create.mockResolvedValueOnce({ id: 'page-1', status: 'DRAFT' });

      await expect(
        service.createDraft('author-1', { slug: 'accueil', locale: 'fr', title: 'Accueil', blocks: {} }),
      ).resolves.toEqual({ id: 'page-1', status: 'DRAFT' });
    });
  });

  describe('publish / unpublish / schedule', () => {
    it('publish sets status PUBLISHED and publishedAt to now', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce({ id: 'page-1' });
      prisma.cmsPage.update.mockResolvedValueOnce({ id: 'page-1', status: 'PUBLISHED' });

      await service.publish('page-1');

      expect(prisma.cmsPage.update).toHaveBeenCalledWith({
        where: { id: 'page-1' },
        data: { status: 'PUBLISHED', publishedAt: expect.any(Date) },
      });
    });

    it('schedule rejects a date in the past', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce({ id: 'page-1' });

      await expect(service.schedule('page-1', new Date(Date.now() - 1000))).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('schedule accepts a future date', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce({ id: 'page-1' });
      prisma.cmsPage.update.mockResolvedValueOnce({ id: 'page-1', status: 'SCHEDULED' });

      const future = new Date(Date.now() + 60_000);
      await expect(service.schedule('page-1', future)).resolves.toEqual({ id: 'page-1', status: 'SCHEDULED' });
    });

    it('throws when the page does not exist', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce(null);

      await expect(service.publish('missing')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('public reads', () => {
    it('findPublic throws for a page that is not PUBLISHED', async () => {
      prisma.cmsPage.findUnique.mockResolvedValueOnce({ id: 'page-1', status: 'DRAFT' });

      await expect(service.findPublic('accueil', 'fr')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('findPublic returns a PUBLISHED page', async () => {
      const page = { id: 'page-1', status: 'PUBLISHED' };
      prisma.cmsPage.findUnique.mockResolvedValueOnce(page);

      await expect(service.findPublic('accueil', 'fr')).resolves.toEqual(page);
    });
  });
});
