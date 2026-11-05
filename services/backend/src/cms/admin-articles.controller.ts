import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { ArticlesService } from './articles.service.js';
import { CreateArticleDto } from './dto/create-article.dto.js';
import { UpdateArticleDto } from './dto/update-article.dto.js';
import { ScheduleContentDto } from './dto/schedule-content.dto.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/cms/articles')
export class AdminArticlesController {
  constructor(
    private readonly articlesService: ArticlesService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  @RequirePermission('cms', 'read')
  list() {
    return this.articlesService.listAdmin();
  }

  @Get(':id')
  @RequirePermission('cms', 'read')
  findOne(@Param('id') id: string) {
    return this.articlesService.getByIdAdmin(id);
  }

  @Post()
  @RequirePermission('cms', 'create')
  async create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateArticleDto) {
    const article = await this.articlesService.createDraft(user.id, { ...dto, locale: dto.locale ?? 'fr' });
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.article.create',
      targetType: 'Article',
      targetId: article.id,
      result: 'SUCCESS',
      metadata: { slug: article.slug, locale: article.locale, category: article.category },
    });
    return article;
  }

  @Patch(':id')
  @RequirePermission('cms', 'update')
  update(@Param('id') id: string, @Body() dto: UpdateArticleDto) {
    return this.articlesService.update(id, dto);
  }

  @Post(':id/publish')
  @RequirePermission('cms', 'approve')
  async publish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const article = await this.articlesService.publish(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.article.publish',
      targetType: 'Article',
      targetId: article.id,
      result: 'SUCCESS',
    });
    return article;
  }

  @Post(':id/unpublish')
  @RequirePermission('cms', 'approve')
  async unpublish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const article = await this.articlesService.unpublish(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.article.unpublish',
      targetType: 'Article',
      targetId: article.id,
      result: 'SUCCESS',
    });
    return article;
  }

  @Post(':id/schedule')
  @RequirePermission('cms', 'approve')
  schedule(@Param('id') id: string, @Body() dto: ScheduleContentDto) {
    return this.articlesService.schedule(id, new Date(dto.publishAt));
  }

  @Delete(':id')
  @RequirePermission('cms', 'delete')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const article = await this.articlesService.remove(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.article.delete',
      targetType: 'Article',
      targetId: article.id,
      result: 'SUCCESS',
    });
    return article;
  }
}
