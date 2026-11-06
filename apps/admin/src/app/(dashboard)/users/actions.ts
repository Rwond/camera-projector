"use server";

import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

export async function updateRoleAction(userId: string, formData: FormData) {
  const adminRole = String(formData.get("adminRole") ?? "");

  await adminFetch(`/admin/users/${userId}/admin-role`, {
    method: "PATCH",
    body: JSON.stringify({ adminRole: adminRole || null }),
  });

  revalidatePath("/users");
}
