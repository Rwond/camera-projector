import { adminFetch, ApiError } from "@/lib/api";
import type { Media } from "@/lib/types";
import { deleteMediaAction, registerMediaAction } from "./actions";

export default async function MediaPage() {
  let media: Media[] = [];
  let accessDenied = false;

  try {
    media = await adminFetch<Media[]>("/admin/cms/media");
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return <p className="text-neutral-400">Votre rôle ne vous donne pas accès aux médias.</p>;
  }

  return (
    <div className="flex flex-col gap-8">
      <h1 className="text-2xl font-semibold">Médias</h1>
      <p className="text-sm text-neutral-500">
        Catalogue de métadonnées uniquement — l&apos;hébergement du fichier (CDN/stockage objet)
        n&apos;est pas encore intégré ; l&apos;URL doit déjà pointer vers un fichier accessible.
      </p>

      <form
        action={registerMediaAction}
        className="flex flex-wrap items-end gap-4 rounded-lg border border-neutral-800 p-4"
      >
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Nom de fichier
          <input name="filename" required className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-1 flex-col gap-1 text-sm text-neutral-300">
          URL
          <input name="url" type="url" required className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Type MIME
          <input
            name="mimeType"
            required
            placeholder="image/png"
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <label className="flex w-28 flex-col gap-1 text-sm text-neutral-300">
          Taille (octets)
          <input
            name="sizeBytes"
            type="number"
            required
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Texte alternatif
          <input name="altText" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <button type="submit" className="rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900">
          Enregistrer
        </button>
      </form>

      {media.length === 0 ? (
        <p className="text-neutral-500">Aucun média enregistré pour le moment.</p>
      ) : (
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-400">
              <th className="py-2 pr-4 font-medium">Nom</th>
              <th className="py-2 pr-4 font-medium">URL</th>
              <th className="py-2 pr-4 font-medium">Type</th>
              <th className="py-2 pr-4 font-medium">Taille</th>
              <th className="py-2 pr-4 font-medium"></th>
            </tr>
          </thead>
          <tbody>
            {media.map((item) => {
              const remove = deleteMediaAction.bind(null, item.id);
              return (
                <tr key={item.id} className="border-b border-neutral-900">
                  <td className="py-2 pr-4">{item.filename}</td>
                  <td className="max-w-xs truncate py-2 pr-4">
                    <a href={item.url} target="_blank" rel="noreferrer" className="text-sky-400 hover:underline">
                      {item.url}
                    </a>
                  </td>
                  <td className="py-2 pr-4">{item.mimeType}</td>
                  <td className="py-2 pr-4">{(item.sizeBytes / 1024).toFixed(1)} Ko</td>
                  <td className="py-2 pr-4">
                    <form action={remove}>
                      <button type="submit" className="text-red-400 hover:text-red-300">
                        Supprimer
                      </button>
                    </form>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}
