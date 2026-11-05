import { ConflictException, BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CmsPage, Prisma } from '../generated/prisma/client.js';

export interface CreatePageInput {
  slug: string;
  locale: string;
  title: string;
  blocks: Record<string, unknown>;
  seoTitle?: string;
  seoDescription?: string;
}

export interface UpdatePageInput {
  title?: string;
  blocks?: Record<string, unknown>;
  seoTitle?: string;
  seoDescription?: string;
}

@Injectable()
export class PagesService {
  constructor(private readonly prisma: PrismaService) {}

  async createDraft(authorId: string, input: CreatePageInput): Promise<CmsPage> {
    const existing = await this.prisma.cmsPage.findUnique({
      where: { slug_locale: { slug: input.slug, locale: input.locale } },
    });
    if (existing) {
      throw new ConflictException('Une page existe déjà avec ce slug pour cette langue.');
    }

    return this.prisma.cmsPage.create({
      data: { ...input, blocks: input.blocks as Prisma.InputJsonValue, authorId },
    });
  }

  async update(id: string, input: UpdatePageInput): Promise<CmsPage> {
    await this.getByIdAdmin(id);
    return this.prisma.cmsPage.update({
      where: { id },
      data: { ...input, blocks: input.blocks as Prisma.InputJsonValue | undefined },
    });
  }

  async publish(id: string): Promise<CmsPage> {
    await this.getByIdAdmin(id);
    return this.prisma.cmsPage.update({
      where: { id },
      data: { status: 'PUBLISHED', publishedAt: new Date() },
    });
  }

  async unpublish(id: string): Promise<CmsPage> {
    await this.getByIdAdmin(id);
    return this.prisma.cmsPage.update({ where: { id }, data: { status: 'UNPUBLISHED' } });
  }

  async schedule(id: string, publishAt: Date): Promise<CmsPage> {
    await this.getByIdAdmin(id);
    if (publishAt.getTime() <= Date.now()) {
      throw new BadRequestException('La date de publication programmée doit être dans le futur.');
    }
    return this.prisma.cmsPage.update({
      where: { id },
      data: { status: 'SCHEDULED', publishedAt: publishAt },
    });
  }

  async remove(id: string): Promise<CmsPage> {
    await this.getByIdAdmin(id);
    return this.prisma.cmsPage.delete({ where: { id } });
  }

  async getByIdAdmin(id: string): Promise<CmsPage> {
    const page = await this.prisma.cmsPage.findUnique({ where: { id } });
    if (!page) {
      throw new NotFoundException('Page introuvable.');
    }
    return page;
  }

  listAdmin(): Promise<CmsPage[]> {
    return this.prisma.cmsPage.findMany({ orderBy: { updatedAt: 'desc' } });
  }

  async findPublic(slug: string, locale: string): Promise<CmsPage> {
    const page = await this.prisma.cmsPage.findUnique({ where: { slug_locale: { slug, locale } } });
    if (!page || page.status !== 'PUBLISHED') {
      throw new NotFoundException('Page introuvable.');
    }
    return page;
  }

  listPublic(locale: string): Promise<CmsPage[]> {
    return this.prisma.cmsPage.findMany({ where: { locale, status: 'PUBLISHED' } });
  }
}
