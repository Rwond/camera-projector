import { adminFetch, ApiError } from "@/lib/api";
import type { Article } from "@/lib/types";
import { BlockEditor } from "@/components/BlockEditor";
import {
  deleteArticleAction,
  publishArticleAction,
  scheduleArticleAction,
  unpublishArticleAction,
  updateArticleAction,
} from "../actions";

export default async function EditArticlePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let article: Article | null = null;
  let accessDenied = false;
  try {
    article = await adminFetch<Article>(`/admin/cms/articles/${id}`);
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) return <p className="text-neutral-400">Votre rôle ne vous donne pas accès au CMS.</p>;
  if (!article) return <p className="text-neutral-400">Article introuvable.</p>;

  const update = updateArticleAction.bind(null, id);
  const publish = publishArticleAction.bind(null, id);
  const unpublish = unpublishArticleAction.bind(null, id);
  const schedule = scheduleArticleAction.bind(null, id);
  const remove = deleteArticleAction.bind(null, id);

  return (
    <div className="flex flex-col gap-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">{article.title}</h1>
          <p className="text-sm text-neutral-500">
            {article.slug} · {article.locale} · statut : {article.status}
          </p>
        </div>
        <div className="flex gap-2">
          {article.status !== "PUBLISHED" && (
            <form action={publish}>
              <button type="submit" className="rounded-md bg-emerald-600 px-3 py-1.5 text-sm text-white">
                Publier
              </button>
            </form>
          )}
          {article.status === "PUBLISHED" && (
            <form action={unpublish}>
              <button type="submit" className="rounded-md bg-neutral-700 px-3 py-1.5 text-sm text-white">
                Dépublier
              </button>
            </form>
          )}
          <form action={remove}>
            <button type="submit" className="rounded-md bg-red-700 px-3 py-1.5 text-sm text-white">
              Supprimer
            </button>
          </form>
        </div>
      </div>

      <form action={schedule} className="flex items-end gap-2 rounded-lg border border-neutral-800 p-4">
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Programmer la publication
          <input
            type="datetime-local"
            name="publishAt"
            required
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <button type="submit" className="rounded-md border border-neutral-700 px-3 py-2 text-sm text-neutral-200">
          Programmer
        </button>
      </form>

      <form action={update} className="flex flex-col gap-4">
        <div className="flex gap-4">
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Titre
            <input
              name="title"
              defaultValue={article.title}
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
          <label className="flex w-40 flex-col gap-1 text-sm text-neutral-300">
            Catégorie
            <select
              name="category"
              defaultValue={article.category}
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            >
              <option value="NEWS">Actualité</option>
              <option value="GUIDE">Guide</option>
              <option value="FAQ">FAQ</option>
            </select>
          </label>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-sm text-neutral-300">Contenu</span>
          <BlockEditor name="bodyJson" initialBlocks={article.body?.blocks ?? []} />
        </div>

        <button
          type="submit"
          className="self-start rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900"
        >
          Enregistrer
        </button>
      </form>
    </div>
  );
}
