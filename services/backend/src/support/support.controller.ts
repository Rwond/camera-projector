import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { SupportService } from './support.service.js';
import { CreateTicketDto } from './dto/create-ticket.dto.js';
import { AddMessageDto } from './dto/add-message.dto.js';

@UseGuards(JwtAuthGuard)
@Controller('support/tickets')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateTicketDto) {
    return this.supportService.createTicket(user.id, dto.category, dto.message);
  }

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.supportService.listForUser(user.id);
  }

  @Get(':id')
  findOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.supportService.getForUser(id, user.id);
  }

  @Post(':id/messages')
  addMessage(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() dto: AddMessageDto) {
    return this.supportService.addMessageAsRequester(id, user.id, dto.body);
  }
}
