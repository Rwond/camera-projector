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

export type Block =
  | { type: "heading"; text: string; level?: 1 | 2 | 3 }
  | { type: "text"; body: string }
  | { type: "cta"; label: string; href: string }
  | { type: "image"; src: string; alt: string };

export interface BlockContent {
  blocks: Block[];
}

export type CmsStatus = "DRAFT" | "IN_REVIEW" | "PUBLISHED" | "SCHEDULED" | "UNPUBLISHED";

export interface CmsPage {
  id: string;
  slug: string;
  locale: string;
  title: string;
  blocks: BlockContent;
  status: CmsStatus;
  seoTitle: string | null;
  seoDescription: string | null;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export type ArticleCategory = "NEWS" | "GUIDE" | "FAQ";

export interface Article {
  id: string;
  slug: string;
  locale: string;
  title: string;
  body: BlockContent;
  category: ArticleCategory;
  status: CmsStatus;
  publishedAt: string | null;
  createdAt: string;
}

export interface Media {
  id: string;
  filename: string;
  url: string;
  altText: string | null;
  mimeType: string;
  sizeBytes: number;
  createdAt: string;
}
