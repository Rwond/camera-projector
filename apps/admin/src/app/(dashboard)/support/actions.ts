"use server";

import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

export async function addMessageAction(ticketId: string, formData: FormData) {
  const body = String(formData.get("body") ?? "");
  const isInternalNote = formData.get("isInternalNote") === "on";

  await adminFetch(`/admin/support/tickets/${ticketId}/messages`, {
    method: "POST",
    body: JSON.stringify({ body, isInternalNote }),
  });

  revalidatePath(`/support/${ticketId}`);
}

export async function updateTicketAction(ticketId: string, formData: FormData) {
  const status = String(formData.get("status") ?? "");
  const priority = String(formData.get("priority") ?? "");

  await adminFetch(`/admin/support/tickets/${ticketId}`, {
    method: "PATCH",
    body: JSON.stringify({ status, priority }),
  });

  revalidatePath(`/support/${ticketId}`);
  revalidatePath("/support");
}
