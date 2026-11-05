import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { AuditService } from '../rbac/audit.service.js';
import { PagesService } from './pages.service.js';
import { CreatePageDto } from './dto/create-page.dto.js';
import { UpdatePageDto } from './dto/update-page.dto.js';
import { ScheduleContentDto } from './dto/schedule-content.dto.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/cms/pages')
export class AdminPagesController {
  constructor(
    private readonly pagesService: PagesService,
    private readonly auditService: AuditService,
  ) {}

  @Get()
  @RequirePermission('cms', 'read')
  list() {
    return this.pagesService.listAdmin();
  }

  @Get(':id')
  @RequirePermission('cms', 'read')
  findOne(@Param('id') id: string) {
    return this.pagesService.getByIdAdmin(id);
  }

  @Post()
  @RequirePermission('cms', 'create')
  async create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreatePageDto) {
    const page = await this.pagesService.createDraft(user.id, { ...dto, locale: dto.locale ?? 'fr' });
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.page.create',
      targetType: 'CmsPage',
      targetId: page.id,
      result: 'SUCCESS',
      metadata: { slug: page.slug, locale: page.locale },
    });
    return page;
  }

  @Patch(':id')
  @RequirePermission('cms', 'update')
  update(@Param('id') id: string, @Body() dto: UpdatePageDto) {
    return this.pagesService.update(id, dto);
  }

  @Post(':id/publish')
  @RequirePermission('cms', 'approve')
  async publish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const page = await this.pagesService.publish(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.page.publish',
      targetType: 'CmsPage',
      targetId: page.id,
      result: 'SUCCESS',
    });
    return page;
  }

  @Post(':id/unpublish')
  @RequirePermission('cms', 'approve')
  async unpublish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const page = await this.pagesService.unpublish(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.page.unpublish',
      targetType: 'CmsPage',
      targetId: page.id,
      result: 'SUCCESS',
    });
    return page;
  }

  @Post(':id/schedule')
  @RequirePermission('cms', 'approve')
  schedule(@Param('id') id: string, @Body() dto: ScheduleContentDto) {
    return this.pagesService.schedule(id, new Date(dto.publishAt));
  }

  @Delete(':id')
  @RequirePermission('cms', 'delete')
  async remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    const page = await this.pagesService.remove(id);
    await this.auditService.log({
      actorId: user.id,
      action: 'cms.page.delete',
      targetType: 'CmsPage',
      targetId: page.id,
      result: 'SUCCESS',
    });
    return page;
  }
}
