export type TicketCategory =
  | "ACCOUNT"
  | "PAYMENT"
  | "CONNECTION"
  | "QUALITY"
  | "COMPATIBILITY"
  | "HARDWARE"
  | "SECURITY";

export type TicketPriority = "LOW" | "MEDIUM" | "HIGH" | "URGENT";

export type TicketStatus = "OPEN" | "IN_PROGRESS" | "WAITING_USER" | "RESOLVED" | "CLOSED";

export interface SupportTicket {
  id: string;
  requesterId: string;
  assignedToId: string | null;
  category: TicketCategory;
  priority: TicketPriority;
  status: TicketStatus;
  createdAt: string;
  updatedAt: string;
}

export interface SupportMessage {
  id: string;
  ticketId: string;
  authorId: string;
  body: string;
  isInternalNote: boolean;
  createdAt: string;
}

export interface TicketWithMessages extends SupportTicket {
  messages: SupportMessage[];
}
