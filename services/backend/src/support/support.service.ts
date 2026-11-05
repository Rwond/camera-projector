import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  SupportMessage,
  SupportTicket,
  TicketCategory,
  TicketPriority,
  TicketStatus,
} from '../generated/prisma/client.js';

export interface TicketWithMessages extends SupportTicket {
  messages: SupportMessage[];
}

export interface UpdateTicketInput {
  status?: TicketStatus;
  priority?: TicketPriority;
  assignedToId?: string | null;
}

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  createTicket(requesterId: string, category: TicketCategory, message: string): Promise<TicketWithMessages> {
    return this.prisma.supportTicket.create({
      data: {
        requesterId,
        category,
        messages: { create: { authorId: requesterId, body: message } },
      },
      include: { messages: true },
    });
  }

  listForUser(userId: string): Promise<SupportTicket[]> {
    return this.prisma.supportTicket.findMany({ where: { requesterId: userId }, orderBy: { createdAt: 'desc' } });
  }

  async getForUser(ticketId: string, userId: string): Promise<TicketWithMessages> {
    const ticket = await this.getTicketOrThrow(ticketId);
    if (ticket.requesterId !== userId) {
      throw new ForbiddenException("Vous n'avez pas accès à ce ticket.");
    }
    const messages = await this.prisma.supportMessage.findMany({
      where: { ticketId, isInternalNote: false },
      orderBy: { createdAt: 'asc' },
    });
    return { ...ticket, messages };
  }

  async addMessageAsRequester(ticketId: string, userId: string, body: string): Promise<SupportMessage> {
    const ticket = await this.getTicketOrThrow(ticketId);
    if (ticket.requesterId !== userId) {
      throw new ForbiddenException("Vous n'avez pas accès à ce ticket.");
    }
    if (ticket.status === 'CLOSED') {
      throw new BadRequestException('Ce ticket est clôturé.');
    }
    return this.prisma.supportMessage.create({ data: { ticketId, authorId: userId, body } });
  }

  listForStaff(filters: { status?: TicketStatus; category?: TicketCategory } = {}): Promise<SupportTicket[]> {
    return this.prisma.supportTicket.findMany({ where: filters, orderBy: { createdAt: 'desc' } });
  }

  async getForStaff(ticketId: string): Promise<TicketWithMessages> {
    const ticket = await this.getTicketOrThrow(ticketId);
    const messages = await this.prisma.supportMessage.findMany({
      where: { ticketId },
      orderBy: { createdAt: 'asc' },
    });
    return { ...ticket, messages };
  }

  addMessageAsStaff(
    ticketId: string,
    staffUserId: string,
    body: string,
    isInternalNote: boolean,
  ): Promise<SupportMessage> {
    return this.getTicketOrThrow(ticketId).then(() =>
      this.prisma.supportMessage.create({ data: { ticketId, authorId: staffUserId, body, isInternalNote } }),
    );
  }

  async update(ticketId: string, input: UpdateTicketInput): Promise<SupportTicket> {
    await this.getTicketOrThrow(ticketId);
    return this.prisma.supportTicket.update({ where: { id: ticketId }, data: input });
  }

  private async getTicketOrThrow(ticketId: string): Promise<SupportTicket> {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) {
      throw new NotFoundException('Ticket introuvable.');
    }
    return ticket;
  }
}
