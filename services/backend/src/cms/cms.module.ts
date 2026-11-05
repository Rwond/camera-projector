import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RbacModule } from '../rbac/rbac.module.js';
import { PagesService } from './pages.service.js';
import { PagesController } from './pages.controller.js';
import { AdminPagesController } from './admin-pages.controller.js';
import { ArticlesService } from './articles.service.js';
import { ArticlesController } from './articles.controller.js';
import { AdminArticlesController } from './admin-articles.controller.js';
import { MediaService } from './media.service.js';
import { AdminMediaController } from './admin-media.controller.js';

@Module({
  imports: [AuthModule, RbacModule],
  controllers: [
    PagesController,
    AdminPagesController,
    ArticlesController,
    AdminArticlesController,
    AdminMediaController,
  ],
  providers: [PagesService, ArticlesService, MediaService],
  exports: [PagesService, ArticlesService, MediaService],
})
export class CmsModule {}
