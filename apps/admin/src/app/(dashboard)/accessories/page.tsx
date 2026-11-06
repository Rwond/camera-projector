import { adminFetch, ApiError } from "@/lib/api";
import type { Accessory } from "@/lib/types";
import { createAccessoryAction } from "./actions";

export default async function AccessoriesPage() {
  let accessories: Accessory[] = [];
  let accessDenied = false;

  try {
    accessories = await adminFetch<Accessory[]>("/admin/accessories");
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return <p className="text-neutral-400">Votre rôle ne vous donne pas accès au catalogue accessoires.</p>;
  }

  return (
    <div className="flex flex-col gap-8">
      <h1 className="text-2xl font-semibold">Catalogue accessoires</h1>

      <form
        action={createAccessoryAction}
        className="flex flex-wrap items-end gap-4 rounded-lg border border-neutral-800 p-4"
      >
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Numéro de série
          <input
            name="serialNumber"
            required
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Modèle
          <input
            name="model"
            required
            placeholder="SWVERTEX Universal Projector"
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Firmware
          <input name="firmwareVersion" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Lot
          <input name="batchNumber" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <button type="submit" className="rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900">
          Ajouter au catalogue
        </button>
      </form>

      {accessories.length === 0 ? (
        <p className="text-neutral-500">Aucun accessoire au catalogue pour le moment.</p>
      ) : (
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-400">
              <th className="py-2 pr-4 font-medium">N° de série</th>
              <th className="py-2 pr-4 font-medium">Modèle</th>
              <th className="py-2 pr-4 font-medium">Firmware</th>
              <th className="py-2 pr-4 font-medium">Statut vente</th>
              <th className="py-2 pr-4 font-medium">État</th>
            </tr>
          </thead>
          <tbody>
            {accessories.map((accessory) => (
              <tr key={accessory.id} className="border-b border-neutral-900">
                <td className="py-2 pr-4 font-mono text-xs">{accessory.serialNumber}</td>
                <td className="py-2 pr-4">{accessory.model}</td>
                <td className="py-2 pr-4">{accessory.firmwareVersion ?? "—"}</td>
                <td className="py-2 pr-4">{accessory.saleStatus}</td>
                <td className="py-2 pr-4">{accessory.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
