import { adminFetch, ApiError } from "@/lib/api";

interface AuditLogEntry {
  id: string;
  actorId: string | null;
  action: string;
  targetType: string;
  targetId: string | null;
  result: "SUCCESS" | "FAILURE";
  metadata: Record<string, unknown> | null;
  createdAt: string;
}

export default async function AuditLogPage() {
  let entries: AuditLogEntry[] = [];
  let accessDenied = false;

  try {
    entries = await adminFetch<AuditLogEntry[]>("/admin/audit-log");
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return (
      <div className="flex flex-col gap-2">
        <h1 className="text-2xl font-semibold">Journal d&apos;audit</h1>
        <p className="text-neutral-400">
          Votre rôle ne vous donne pas accès au journal d&apos;audit.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-semibold">Journal d&apos;audit</h1>
      {entries.length === 0 ? (
        <p className="text-neutral-500">Aucune action enregistrée pour le moment.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="border-b border-neutral-800 text-neutral-400">
                <th className="py-2 pr-4 font-medium">Date</th>
                <th className="py-2 pr-4 font-medium">Action</th>
                <th className="py-2 pr-4 font-medium">Cible</th>
                <th className="py-2 pr-4 font-medium">Résultat</th>
                <th className="py-2 pr-4 font-medium">Détails</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((entry) => (
                <tr key={entry.id} className="border-b border-neutral-900">
                  <td className="py-2 pr-4 whitespace-nowrap text-neutral-400">
                    {new Date(entry.createdAt).toLocaleString("fr-FR")}
                  </td>
                  <td className="py-2 pr-4 font-mono text-xs">{entry.action}</td>
                  <td className="py-2 pr-4">
                    {entry.targetType}
                    {entry.targetId ? ` #${entry.targetId.slice(0, 8)}` : ""}
                  </td>
                  <td className="py-2 pr-4">
                    <span className={entry.result === "SUCCESS" ? "text-emerald-400" : "text-red-400"}>
                      {entry.result === "SUCCESS" ? "Succès" : "Échec"}
                    </span>
                  </td>
                  <td className="py-2 pr-4 text-xs text-neutral-500">
                    {entry.metadata ? JSON.stringify(entry.metadata) : "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
