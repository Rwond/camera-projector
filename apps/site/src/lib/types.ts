export type Block =
  | { type: 'heading'; text: string; level?: 1 | 2 | 3 }
  | { type: 'text'; body: string }
  | { type: 'cta'; label: string; href: string }
  | { type: 'image'; src: string; alt: string };

export interface BlockContent {
  blocks: Block[];
}

export interface CmsPage {
  id: string;
  slug: string;
  locale: string;
  title: string;
  blocks: BlockContent | Record<string, unknown>;
  seoTitle: string | null;
  seoDescription: string | null;
  publishedAt: string | null;
}

export type ArticleCategory = 'NEWS' | 'GUIDE' | 'FAQ';

export interface Article {
  id: string;
  slug: string;
  locale: string;
  title: string;
  body: BlockContent | Record<string, unknown>;
  category: ArticleCategory;
  publishedAt: string | null;
}

export type ProjectionMode = 'MODE_A_USB_C' | 'MODE_B_WIRELESS' | 'MODE_C_LENS' | 'CAMERA_SHARE' | 'SCREEN_SHARE';

export type CompatibilityResult = 'UNTESTED' | 'IN_TEST' | 'VALIDATED' | 'PARTIAL' | 'NOT_COMPATIBLE' | 'RETIRED';

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
