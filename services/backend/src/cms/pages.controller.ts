import { Controller, Get, Param, Query } from '@nestjs/common';
import { PagesService } from './pages.service.js';

/** Lecture publique, sans authentification — alimente le site public (§9). */
@Controller('cms/pages')
export class PagesController {
  constructor(private readonly pagesService: PagesService) {}

  @Get()
  list(@Query('locale') locale = 'fr') {
    return this.pagesService.listPublic(locale);
  }

  @Get(':locale/:slug')
  findOne(@Param('locale') locale: string, @Param('slug') slug: string) {
    return this.pagesService.findPublic(slug, locale);
  }
}
