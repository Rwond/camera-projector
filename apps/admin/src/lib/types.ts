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

export const ADMIN_ROLES = [
  "SUPER_ADMIN",
  "PRODUCT_MANAGER",
  "SUPPORT_AGENT",
  "FINANCE_MANAGER",
  "TECHNICAL_OPERATOR",
  "CONTENT_MANAGER",
  "READ_ONLY_AUDITOR",
] as const;
export type AdminRole = (typeof ADMIN_ROLES)[number];

export interface AdminUser {
  id: string;
  email: string;
  status: string;
  adminRole: AdminRole | null;
  createdAt: string;
}

export type AccessorySaleStatus = "IN_STOCK" | "SOLD" | "RETURNED";
export type AccessoryStatus = "ACTIVE" | "DEFECTIVE" | "RETIRED";

export interface Accessory {
  id: string;
  serialNumber: string;
  model: string;
  firmwareVersion: string | null;
  batchNumber: string | null;
  warrantyExpiresAt: string | null;
  ownerId: string | null;
  saleStatus: AccessorySaleStatus;
  status: AccessoryStatus;
  createdAt: string;
}

export type ProjectionMode = "MODE_A_USB_C" | "MODE_B_WIRELESS" | "MODE_C_LENS" | "CAMERA_SHARE" | "SCREEN_SHARE";

export type CompatibilityResult = "UNTESTED" | "IN_TEST" | "VALIDATED" | "PARTIAL" | "NOT_COMPATIBLE" | "RETIRED";

export interface CompatibilityRecord {
  id: string;
  deviceModel: string;
  accessoryModel: string | null;
  osName: string;
  osVersion: string | null;
  mode: ProjectionMode;
  feature: string;
  result: CompatibilityResult;
  testedVersion: string | null;
  testedAt: string | null;
}
