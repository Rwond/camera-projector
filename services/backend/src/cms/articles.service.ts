import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { Article, ArticleCategory, Prisma } from '../generated/prisma/client.js';

export interface CreateArticleInput {
  slug: string;
  locale: string;
  title: string;
  body: Record<string, unknown>;
  category: ArticleCategory;
}

export interface UpdateArticleInput {
  title?: string;
  body?: Record<string, unknown>;
  category?: ArticleCategory;
}

@Injectable()
export class ArticlesService {
  constructor(private readonly prisma: PrismaService) {}

  async createDraft(authorId: string, input: CreateArticleInput): Promise<Article> {
    const existing = await this.prisma.article.findUnique({
      where: { slug_locale: { slug: input.slug, locale: input.locale } },
    });
    if (existing) {
      throw new ConflictException('Un article existe déjà avec ce slug pour cette langue.');
    }

    return this.prisma.article.create({
      data: { ...input, body: input.body as Prisma.InputJsonValue, authorId },
    });
  }

  async update(id: string, input: UpdateArticleInput): Promise<Article> {
    await this.getByIdAdmin(id);
    return this.prisma.article.update({
      where: { id },
      data: { ...input, body: input.body as Prisma.InputJsonValue | undefined },
    });
  }

  async publish(id: string): Promise<Article> {
    await this.getByIdAdmin(id);
    return this.prisma.article.update({
      where: { id },
      data: { status: 'PUBLISHED', publishedAt: new Date() },
    });
  }

  async unpublish(id: string): Promise<Article> {
    await this.getByIdAdmin(id);
    return this.prisma.article.update({ where: { id }, data: { status: 'UNPUBLISHED' } });
  }

  async schedule(id: string, publishAt: Date): Promise<Article> {
    await this.getByIdAdmin(id);
    if (publishAt.getTime() <= Date.now()) {
      throw new BadRequestException('La date de publication programmée doit être dans le futur.');
    }
    return this.prisma.article.update({
      where: { id },
      data: { status: 'SCHEDULED', publishedAt: publishAt },
    });
  }

  async remove(id: string): Promise<Article> {
    await this.getByIdAdmin(id);
    return this.prisma.article.delete({ where: { id } });
  }

  async getByIdAdmin(id: string): Promise<Article> {
    const article = await this.prisma.article.findUnique({ where: { id } });
    if (!article) {
      throw new NotFoundException('Article introuvable.');
    }
    return article;
  }

  listAdmin(): Promise<Article[]> {
    return this.prisma.article.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async findPublic(slug: string, locale: string): Promise<Article> {
    const article = await this.prisma.article.findUnique({ where: { slug_locale: { slug, locale } } });
    if (!article || article.status !== 'PUBLISHED') {
      throw new NotFoundException('Article introuvable.');
    }
    return article;
  }

  listPublic(locale: string, category?: ArticleCategory): Promise<Article[]> {
    return this.prisma.article.findMany({
      where: { locale, status: 'PUBLISHED', ...(category ? { category } : {}) },
      orderBy: { publishedAt: 'desc' },
    });
  }
}
