import { Controller, Get, Param, Query } from '@nestjs/common';
import { ArticlesService } from './articles.service.js';
import type { ArticleCategory } from '../generated/prisma/client.js';

/** Lecture publique, sans authentification — actualités, guides et FAQ (§9). */
@Controller('cms/articles')
export class ArticlesController {
  constructor(private readonly articlesService: ArticlesService) {}

  @Get()
  list(@Query('locale') locale = 'fr', @Query('category') category?: ArticleCategory) {
    return this.articlesService.listPublic(locale, category);
  }

  @Get(':locale/:slug')
  findOne(@Param('locale') locale: string, @Param('slug') slug: string) {
    return this.articlesService.findPublic(slug, locale);
  }
}
