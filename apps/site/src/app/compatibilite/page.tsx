import { listCompatibility } from "@/lib/api";

const RESULT_LABELS: Record<string, string> = {
  VALIDATED: "Validé",
  PARTIAL: "Partiellement compatible",
  NOT_COMPATIBLE: "Non compatible",
  IN_TEST: "En test",
  UNTESTED: "À tester",
  RETIRED: "Retiré",
};

const MODE_LABELS: Record<string, string> = {
  MODE_A_USB_C: "Mode A — Module USB-C",
  MODE_B_WIRELESS: "Mode B — Projecteur Wi-Fi",
  MODE_C_LENS: "Mode C — Lentille optique",
  CAMERA_SHARE: "Partage caméra",
  SCREEN_SHARE: "Partage d'écran",
};

export default async function CompatibilitePage() {
  const records = await listCompatibility({});

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Compatibilité</h1>
        <p className="mt-2 text-neutral-600 dark:text-neutral-400">
          Résultats de tests réels par appareil, accessoire et mode de projection. Une
          fonctionnalité n&apos;est annoncée que si elle a été validée.
        </p>
      </div>

      {records.length === 0 ? (
        <p className="text-neutral-500">Aucun résultat de compatibilité publié pour le moment.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="border-b border-neutral-200 dark:border-neutral-800">
                <th className="py-2 pr-4 font-medium">Appareil</th>
                <th className="py-2 pr-4 font-medium">Accessoire</th>
                <th className="py-2 pr-4 font-medium">Mode</th>
                <th className="py-2 pr-4 font-medium">Fonction</th>
                <th className="py-2 pr-4 font-medium">Résultat</th>
              </tr>
            </thead>
            <tbody>
              {records.map((record) => (
                <tr key={record.id} className="border-b border-neutral-100 dark:border-neutral-900">
                  <td className="py-2 pr-4">
                    {record.deviceModel} ({record.osName}
                    {record.osVersion ? ` ${record.osVersion}` : ""})
                  </td>
                  <td className="py-2 pr-4">{record.accessoryModel ?? "—"}</td>
                  <td className="py-2 pr-4">{MODE_LABELS[record.mode] ?? record.mode}</td>
                  <td className="py-2 pr-4">{record.feature}</td>
                  <td className="py-2 pr-4">{RESULT_LABELS[record.result] ?? record.result}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
