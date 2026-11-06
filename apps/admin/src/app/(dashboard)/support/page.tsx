import Link from "next/link";
import { adminFetch, ApiError } from "@/lib/api";
import type { SupportTicket } from "@/lib/types";

const STATUS_LABELS: Record<string, string> = {
  OPEN: "Ouvert",
  IN_PROGRESS: "En cours",
  WAITING_USER: "Attente client",
  RESOLVED: "Résolu",
  CLOSED: "Clôturé",
};

const STATUS_COLORS: Record<string, string> = {
  OPEN: "text-amber-400",
  IN_PROGRESS: "text-sky-400",
  WAITING_USER: "text-neutral-400",
  RESOLVED: "text-emerald-400",
  CLOSED: "text-neutral-500",
};

export default async function SupportTicketsPage() {
  let tickets: SupportTicket[] = [];
  let accessDenied = false;

  try {
    tickets = await adminFetch<SupportTicket[]>("/admin/support/tickets");
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
        <h1 className="text-2xl font-semibold">Support</h1>
        <p className="text-neutral-400">Votre rôle ne vous donne pas accès aux tickets de support.</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-semibold">Tickets de support</h1>
      {tickets.length === 0 ? (
        <p className="text-neutral-500">Aucun ticket pour le moment.</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="border-b border-neutral-800 text-neutral-400">
                <th className="py-2 pr-4 font-medium">Créé le</th>
                <th className="py-2 pr-4 font-medium">Catégorie</th>
                <th className="py-2 pr-4 font-medium">Priorité</th>
                <th className="py-2 pr-4 font-medium">Statut</th>
              </tr>
            </thead>
            <tbody>
              {tickets.map((ticket) => (
                <tr key={ticket.id} className="border-b border-neutral-900">
                  <td className="py-2 pr-4">
                    <Link href={`/support/${ticket.id}`} className="hover:underline">
                      {new Date(ticket.createdAt).toLocaleString("fr-FR")}
                    </Link>
                  </td>
                  <td className="py-2 pr-4">{ticket.category}</td>
                  <td className="py-2 pr-4">{ticket.priority}</td>
                  <td className={`py-2 pr-4 ${STATUS_COLORS[ticket.status] ?? ""}`}>
                    {STATUS_LABELS[ticket.status] ?? ticket.status}
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
