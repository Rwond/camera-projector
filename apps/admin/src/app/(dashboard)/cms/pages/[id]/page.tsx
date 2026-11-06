import { adminFetch, ApiError } from "@/lib/api";
import type { CmsPage } from "@/lib/types";
import { BlockEditor } from "@/components/BlockEditor";
import {
  deletePageAction,
  publishPageAction,
  schedulePageAction,
  unpublishPageAction,
  updatePageAction,
} from "../actions";

export default async function EditCmsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let page: CmsPage | null = null;
  let accessDenied = false;
  try {
    page = await adminFetch<CmsPage>(`/admin/cms/pages/${id}`);
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) return <p className="text-neutral-400">Votre rôle ne vous donne pas accès au CMS.</p>;
  if (!page) return <p className="text-neutral-400">Page introuvable.</p>;

  const update = updatePageAction.bind(null, id);
  const publish = publishPageAction.bind(null, id);
  const unpublish = unpublishPageAction.bind(null, id);
  const schedule = schedulePageAction.bind(null, id);
  const remove = deletePageAction.bind(null, id);

  return (
    <div className="flex flex-col gap-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">{page.title}</h1>
          <p className="text-sm text-neutral-500">
            {page.slug} · {page.locale} · statut : {page.status}
          </p>
        </div>
        <div className="flex gap-2">
          {page.status !== "PUBLISHED" && (
            <form action={publish}>
              <button type="submit" className="rounded-md bg-emerald-600 px-3 py-1.5 text-sm text-white">
                Publier
              </button>
            </form>
          )}
          {page.status === "PUBLISHED" && (
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
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Titre
          <input
            name="title"
            defaultValue={page.title}
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <div className="flex gap-4">
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Titre SEO
            <input
              name="seoTitle"
              defaultValue={page.seoTitle ?? ""}
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Description SEO
            <input
              name="seoDescription"
              defaultValue={page.seoDescription ?? ""}
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-sm text-neutral-300">Contenu</span>
          <BlockEditor name="blocksJson" initialBlocks={page.blocks?.blocks ?? []} />
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
