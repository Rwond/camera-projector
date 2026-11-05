import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { HealthModule } from './health/health.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { UsersModule } from './users/users.module.js';
import { AuthModule } from './auth/auth.module.js';
import { OrganizationsModule } from './organizations/organizations.module.js';
import { DevicesModule } from './devices/devices.module.js';
import { AccessoriesModule } from './accessories/accessories.module.js';
import { CompatibilityModule } from './compatibility/compatibility.module.js';
import { RbacModule } from './rbac/rbac.module.js';
import { AdminModule } from './admin/admin.module.js';
import { CmsModule } from './cms/cms.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    HealthModule,
    UsersModule,
    AuthModule,
    OrganizationsModule,
    DevicesModule,
    AccessoriesModule,
    CompatibilityModule,
    RbacModule,
    AdminModule,
    CmsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
