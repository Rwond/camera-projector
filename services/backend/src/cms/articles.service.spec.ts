import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ArticlesService } from './articles.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

describe('ArticlesService', () => {
  let service: ArticlesService;
  let prisma: {
    article: {
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      delete: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    prisma = {
      article: { findUnique: vi.fn(), create: vi.fn(), update: vi.fn(), delete: vi.fn(), findMany: vi.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [ArticlesService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get<ArticlesService>(ArticlesService);
  });

  it('createDraft rejects a duplicate slug/locale', async () => {
    prisma.article.findUnique.mockResolvedValueOnce({ id: 'art-1' });

    await expect(
      service.createDraft('author-1', { slug: 'maj-v2', locale: 'fr', title: 'MAJ v2', body: {}, category: 'NEWS' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('publish sets status PUBLISHED and publishedAt to now', async () => {
    prisma.article.findUnique.mockResolvedValueOnce({ id: 'art-1' });
    prisma.article.update.mockResolvedValueOnce({ id: 'art-1', status: 'PUBLISHED' });

    await service.publish('art-1');

    expect(prisma.article.update).toHaveBeenCalledWith({
      where: { id: 'art-1' },
      data: { status: 'PUBLISHED', publishedAt: expect.any(Date) },
    });
  });

  it('findPublic throws for an article that is not PUBLISHED', async () => {
    prisma.article.findUnique.mockResolvedValueOnce({ id: 'art-1', status: 'DRAFT' });

    await expect(service.findPublic('maj-v2', 'fr')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('listPublic filters by category only when provided', async () => {
    prisma.article.findMany.mockResolvedValueOnce([]);

    await service.listPublic('fr', 'FAQ');

    expect(prisma.article.findMany).toHaveBeenCalledWith({
      where: { locale: 'fr', status: 'PUBLISHED', category: 'FAQ' },
      orderBy: { publishedAt: 'desc' },
    });
  });

  it('listPublic omits the category filter when not provided', async () => {
    prisma.article.findMany.mockResolvedValueOnce([]);

    await service.listPublic('fr');

    expect(prisma.article.findMany).toHaveBeenCalledWith({
      where: { locale: 'fr', status: 'PUBLISHED' },
      orderBy: { publishedAt: 'desc' },
    });
  });
});
