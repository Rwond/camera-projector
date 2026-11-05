import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { AccessoriesService } from './accessories.service.js';
import { ClaimAccessoryDto } from './dto/claim-accessory.dto.js';

@UseGuards(JwtAuthGuard)
@Controller('accessories')
export class AccessoriesController {
  constructor(private readonly accessoriesService: AccessoriesService) {}

  @Post('claim')
  claim(@CurrentUser() user: AuthenticatedUser, @Body() dto: ClaimAccessoryDto) {
    return this.accessoriesService.claim(user.id, dto.serialNumber);
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.accessoriesService.listForOwner(user.id);
  }

  @Delete(':id')
  release(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.accessoriesService.release(id, user.id);
  }
}
