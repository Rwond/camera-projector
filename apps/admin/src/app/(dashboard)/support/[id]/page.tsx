import { adminFetch, ApiError } from "@/lib/api";
import type { TicketWithMessages } from "@/lib/types";
import { addMessageAction, updateTicketAction } from "../actions";

const STATUSES = ["OPEN", "IN_PROGRESS", "WAITING_USER", "RESOLVED", "CLOSED"];
const PRIORITIES = ["LOW", "MEDIUM", "HIGH", "URGENT"];

export default async function SupportTicketDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let ticket: TicketWithMessages | null = null;
  let accessDenied = false;

  try {
    ticket = await adminFetch<TicketWithMessages>(`/admin/support/tickets/${id}`);
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return <p className="text-neutral-400">Votre rôle ne vous donne pas accès à ce ticket.</p>;
  }
  if (!ticket) {
    return <p className="text-neutral-400">Ticket introuvable.</p>;
  }

  const addMessage = addMessageAction.bind(null, id);
  const updateTicket = updateTicketAction.bind(null, id);

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-semibold">Ticket — {ticket.category}</h1>
        <p className="text-neutral-500">Ouvert le {new Date(ticket.createdAt).toLocaleString("fr-FR")}</p>
      </div>

      <form action={updateTicket} className="flex flex-wrap items-end gap-4 rounded-lg border border-neutral-800 p-4">
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Statut
          <select
            name="status"
            defaultValue={ticket.status}
            className="rounded-md border border-neutral-700 bg-neutral-800 px-2 py-1"
          >
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Priorité
          <select
            name="priority"
            defaultValue={ticket.priority}
            className="rounded-md border border-neutral-700 bg-neutral-800 px-2 py-1"
          >
            {PRIORITIES.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </label>
        <button type="submit" className="rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900">
          Mettre à jour
        </button>
      </form>

      <div className="flex flex-col gap-3">
        {ticket.messages.map((message) => (
          <div
            key={message.id}
            className={`rounded-lg border p-3 ${
              message.isInternalNote
                ? "border-amber-900/50 bg-amber-950/30"
                : "border-neutral-800 bg-neutral-900"
            }`}
          >
            <div className="mb-1 flex items-center gap-2 text-xs text-neutral-500">
              <span>{new Date(message.createdAt).toLocaleString("fr-FR")}</span>
              {message.isInternalNote && (
                <span className="rounded bg-amber-900/60 px-2 py-0.5 text-amber-300">
                  Note interne — jamais visible du demandeur
                </span>
              )}
            </div>
            <p className="text-sm text-neutral-200">{message.body}</p>
          </div>
        ))}
      </div>

      <form action={addMessage} className="flex flex-col gap-3 rounded-lg border border-neutral-800 p-4">
        <label className="flex flex-col gap-1 text-sm text-neutral-300">
          Répondre
          <textarea
            name="body"
            required
            rows={3}
            className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2 text-neutral-100"
          />
        </label>
        <label className="flex items-center gap-2 text-sm text-neutral-300">
          <input type="checkbox" name="isInternalNote" />
          Note interne (jamais visible du demandeur)
        </label>
        <button
          type="submit"
          className="self-start rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900"
        >
          Envoyer
        </button>
      </form>
    </div>
  );
}
