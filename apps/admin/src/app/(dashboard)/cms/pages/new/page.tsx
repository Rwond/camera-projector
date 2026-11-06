import { BlockEditor } from "@/components/BlockEditor";
import { createPageAction } from "../actions";

export default function NewCmsPage() {
  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-semibold">Nouvelle page</h1>
      <form action={createPageAction} className="flex flex-col gap-4">
        <div className="flex gap-4">
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Slug
            <input
              name="slug"
              required
              placeholder="accueil"
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
          <label className="flex w-32 flex-col gap-1 text-sm text-neutral-300">
            Langue
            <input
              name="locale"
              defaultValue="fr"
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
        </div>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Titre
          <input
            name="title"
            required
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <div className="flex gap-4">
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Titre SEO
            <input name="seoTitle" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
          </label>
          <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
            Description SEO
            <input
              name="seoDescription"
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
            />
          </label>
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-sm text-neutral-300">Contenu</span>
          <BlockEditor name="blocksJson" initialBlocks={[]} />
        </div>

        <button
          type="submit"
          className="self-start rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900"
        >
          Créer en brouillon
        </button>
      </form>
    </div>
  );
}
