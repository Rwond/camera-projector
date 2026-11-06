import { adminFetch } from "@/lib/api";
import type { CompatibilityRecord } from "@/lib/types";
import { createCompatibilityRecordAction } from "./actions";

const MODES = ["MODE_A_USB_C", "MODE_B_WIRELESS", "MODE_C_LENS", "CAMERA_SHARE", "SCREEN_SHARE"];
const RESULTS = ["UNTESTED", "IN_TEST", "VALIDATED", "PARTIAL", "NOT_COMPATIBLE", "RETIRED"];

export default async function CompatibilityPage() {
  const records = await adminFetch<CompatibilityRecord[]>("/compatibility");

  return (
    <div className="flex flex-col gap-8">
      <h1 className="text-2xl font-semibold">Matrice de compatibilité</h1>

      <form
        action={createCompatibilityRecordAction}
        className="flex flex-wrap items-end gap-4 rounded-lg border border-neutral-800 p-4"
      >
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Appareil
          <input name="deviceModel" required className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Accessoire
          <input name="accessoryModel" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          OS
          <input name="osName" required className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Version OS
          <input name="osVersion" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2" />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Mode
          <select name="mode" required className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2">
            {MODES.map((mode) => (
              <option key={mode} value={mode}>
                {mode}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Fonction
          <input
            name="feature"
            required
            placeholder="video, pairing, firmware..."
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Résultat
          <select name="result" className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2">
            {RESULTS.map((result) => (
              <option key={result} value={result}>
                {result}
              </option>
            ))}
          </select>
        </label>
        <button type="submit" className="rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900">
          Publier le résultat
        </button>
      </form>

      {records.length === 0 ? (
        <p className="text-neutral-500">Aucun résultat de compatibilité pour le moment.</p>
      ) : (
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-400">
              <th className="py-2 pr-4 font-medium">Appareil</th>
              <th className="py-2 pr-4 font-medium">Accessoire</th>
              <th className="py-2 pr-4 font-medium">Mode</th>
              <th className="py-2 pr-4 font-medium">Fonction</th>
              <th className="py-2 pr-4 font-medium">Résultat</th>
            </tr>
          </thead>
          <tbody>
            {records.map((record) => (
              <tr key={record.id} className="border-b border-neutral-900">
                <td className="py-2 pr-4">
                  {record.deviceModel} ({record.osName}
                  {record.osVersion ? ` ${record.osVersion}` : ""})
                </td>
                <td className="py-2 pr-4">{record.accessoryModel ?? "—"}</td>
                <td className="py-2 pr-4">{record.mode}</td>
                <td className="py-2 pr-4">{record.feature}</td>
                <td className="py-2 pr-4">{record.result}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
