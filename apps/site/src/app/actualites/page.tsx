import Link from "next/link";
import { listArticles } from "@/lib/api";

export default async function ActualitesPage() {
  const articles = await listArticles("fr", "NEWS");

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-3xl font-bold tracking-tight">Actualités</h1>
      {articles.length === 0 ? (
        <p className="text-neutral-500">Aucune actualité publiée pour le moment.</p>
      ) : (
        <ul className="flex flex-col gap-4">
          {articles.map((article) => (
            <li key={article.id} className="border-b border-neutral-100 pb-4 dark:border-neutral-900">
              <Link href={`/actualites/${article.slug}`} className="text-lg font-medium hover:underline">
                {article.title}
              </Link>
              {article.publishedAt && (
                <p className="text-sm text-neutral-500">
                  {new Date(article.publishedAt).toLocaleDateString("fr-FR")}
                </p>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
