import Link from 'next/link';
import type { Block, BlockContent } from '@/lib/types';

function isBlockContent(content: unknown): content is BlockContent {
  return (
    typeof content === 'object' &&
    content !== null &&
    Array.isArray((content as { blocks?: unknown }).blocks)
  );
}

function renderBlock(block: Block, index: number) {
  switch (block.type) {
    case 'heading': {
      const Tag = (`h${block.level ?? 2}` as unknown) as 'h1' | 'h2' | 'h3';
      return (
        <Tag key={index} className="text-2xl font-semibold tracking-tight text-neutral-900 dark:text-neutral-100">
          {block.text}
        </Tag>
      );
    }
    case 'text':
      return (
        <p key={index} className="text-base leading-relaxed text-neutral-700 dark:text-neutral-300">
          {block.body}
        </p>
      );
    case 'cta':
      return (
        <Link
          key={index}
          href={block.href}
          className="inline-block rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700 dark:bg-neutral-100 dark:text-neutral-900"
        >
          {block.label}
        </Link>
      );
    case 'image':
      // eslint-disable-next-line @next/next/no-img-element
      return <img key={index} src={block.src} alt={block.alt} className="rounded-lg" />;
    default:
      return null;
  }
}

export function BlockRenderer({ content }: { content: unknown }) {
  if (!isBlockContent(content)) {
    return null;
  }

  return <div className="flex flex-col gap-4">{content.blocks.map(renderBlock)}</div>;
}
