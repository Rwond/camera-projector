import { getPage } from "@/lib/api";
import { BlockRenderer } from "@/components/BlockRenderer";

export default async function HomePage() {
  const page = await getPage("fr", "accueil");

  if (!page) {
    return (
      <div className="flex flex-col gap-4">
        <h1 className="text-2xl font-semibold">SWVERTEX CAMERA PROJECTOR</h1>
        <p className="text-neutral-600 dark:text-neutral-400">
          Le contenu de la page d&apos;accueil n&apos;a pas encore été publié depuis
          l&apos;administration.
        </p>
      </div>
    );
  }

  return (
    <article>
      <h1 className="mb-6 text-3xl font-bold tracking-tight">{page.title}</h1>
      <BlockRenderer content={page.blocks} />
    </article>
  );
}
