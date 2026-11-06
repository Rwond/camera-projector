"use server";

import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

export async function registerMediaAction(formData: FormData) {
  const filename = String(formData.get("filename") ?? "");
  const url = String(formData.get("url") ?? "");
  const mimeType = String(formData.get("mimeType") ?? "");
  const sizeBytes = Number(formData.get("sizeBytes") ?? 0);
  const altText = String(formData.get("altText") ?? "") || undefined;

  await adminFetch("/admin/cms/media", {
    method: "POST",
    body: JSON.stringify({ filename, url, mimeType, sizeBytes, altText }),
  });

  revalidatePath("/cms/media");
}

export async function deleteMediaAction(id: string) {
  await adminFetch(`/admin/cms/media/${id}`, { method: "DELETE" });
  revalidatePath("/cms/media");
}
