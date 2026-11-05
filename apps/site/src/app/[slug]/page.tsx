import { notFound } from "next/navigation";
import { getPage } from "@/lib/api";
import { BlockRenderer } from "@/components/BlockRenderer";

export default async function CmsPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const page = await getPage("fr", slug);

  if (!page) {
    notFound();
  }

  return (
    <article>
      <h1 className="mb-6 text-3xl font-bold tracking-tight">{page.title}</h1>
      <BlockRenderer content={page.blocks} />
    </article>
  );
}
