import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { AdminPermissionGuard } from '../rbac/admin-permission.guard.js';
import { RequirePermission } from '../rbac/require-permission.decorator.js';
import { MediaService } from './media.service.js';
import { RegisterMediaDto } from './dto/register-media.dto.js';

@UseGuards(JwtAuthGuard, AdminPermissionGuard)
@Controller('admin/cms/media')
export class AdminMediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Get()
  @RequirePermission('cms', 'read')
  list() {
    return this.mediaService.list();
  }

  @Post()
  @RequirePermission('cms', 'create')
  register(@Body() dto: RegisterMediaDto) {
    return this.mediaService.register(dto);
  }

  @Delete(':id')
  @RequirePermission('cms', 'delete')
  remove(@Param('id') id: string) {
    return this.mediaService.remove(id);
  }
}
