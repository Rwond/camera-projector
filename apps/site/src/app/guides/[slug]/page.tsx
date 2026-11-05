import { notFound } from "next/navigation";
import { getArticle } from "@/lib/api";
import { BlockRenderer } from "@/components/BlockRenderer";

export default async function GuideOrFaqPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const article = await getArticle("fr", slug);

  if (!article) {
    notFound();
  }

  return (
    <article className="flex flex-col gap-6">
      <h1 className="text-3xl font-bold tracking-tight">{article.title}</h1>
      <BlockRenderer content={article.body} />
    </article>
  );
}
