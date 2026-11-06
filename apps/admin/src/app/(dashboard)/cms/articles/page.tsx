import Link from "next/link";
import { adminFetch, ApiError } from "@/lib/api";
import type { Article } from "@/lib/types";

const STATUS_COLORS: Record<string, string> = {
  DRAFT: "text-neutral-400",
  IN_REVIEW: "text-sky-400",
  PUBLISHED: "text-emerald-400",
  SCHEDULED: "text-amber-400",
  UNPUBLISHED: "text-neutral-500",
};

export default async function CmsArticlesListPage() {
  let articles: Article[] = [];
  let accessDenied = false;

  try {
    articles = await adminFetch<Article[]>("/admin/cms/articles");
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return <p className="text-neutral-400">Votre rôle ne vous donne pas accès au CMS.</p>;
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Articles</h1>
        <Link
          href="/cms/articles/new"
          className="rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900"
        >
          Nouvel article
        </Link>
      </div>

      {articles.length === 0 ? (
        <p className="text-neutral-500">Aucun article pour le moment.</p>
      ) : (
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-400">
              <th className="py-2 pr-4 font-medium">Titre</th>
              <th className="py-2 pr-4 font-medium">Catégorie</th>
              <th className="py-2 pr-4 font-medium">Langue</th>
              <th className="py-2 pr-4 font-medium">Statut</th>
            </tr>
          </thead>
          <tbody>
            {articles.map((article) => (
              <tr key={article.id} className="border-b border-neutral-900">
                <td className="py-2 pr-4">
                  <Link href={`/cms/articles/${article.id}`} className="hover:underline">
                    {article.title}
                  </Link>
                </td>
                <td className="py-2 pr-4">{article.category}</td>
                <td className="py-2 pr-4">{article.locale}</td>
                <td className={`py-2 pr-4 ${STATUS_COLORS[article.status] ?? ""}`}>{article.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
