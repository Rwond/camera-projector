"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

function parseBlocks(formData: FormData) {
  const raw = String(formData.get("blocksJson") ?? '{"blocks":[]}');
  return JSON.parse(raw);
}

export async function createPageAction(formData: FormData) {
  const slug = String(formData.get("slug") ?? "");
  const locale = String(formData.get("locale") ?? "fr");
  const title = String(formData.get("title") ?? "");
  const seoTitle = String(formData.get("seoTitle") ?? "") || undefined;
  const seoDescription = String(formData.get("seoDescription") ?? "") || undefined;
  const blocks = parseBlocks(formData);

  await adminFetch("/admin/cms/pages", {
    method: "POST",
    body: JSON.stringify({ slug, locale, title, seoTitle, seoDescription, blocks }),
  });

  revalidatePath("/cms/pages");
  redirect("/cms/pages");
}

export async function updatePageAction(id: string, formData: FormData) {
  const title = String(formData.get("title") ?? "");
  const seoTitle = String(formData.get("seoTitle") ?? "") || undefined;
  const seoDescription = String(formData.get("seoDescription") ?? "") || undefined;
  const blocks = parseBlocks(formData);

  await adminFetch(`/admin/cms/pages/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ title, seoTitle, seoDescription, blocks }),
  });

  revalidatePath(`/cms/pages/${id}`);
  revalidatePath("/cms/pages");
}

export async function publishPageAction(id: string) {
  await adminFetch(`/admin/cms/pages/${id}/publish`, { method: "POST" });
  revalidatePath(`/cms/pages/${id}`);
  revalidatePath("/cms/pages");
}

export async function unpublishPageAction(id: string) {
  await adminFetch(`/admin/cms/pages/${id}/unpublish`, { method: "POST" });
  revalidatePath(`/cms/pages/${id}`);
  revalidatePath("/cms/pages");
}

export async function schedulePageAction(id: string, formData: FormData) {
  const publishAt = String(formData.get("publishAt") ?? "");
  await adminFetch(`/admin/cms/pages/${id}/schedule`, {
    method: "POST",
    body: JSON.stringify({ publishAt: new Date(publishAt).toISOString() }),
  });
  revalidatePath(`/cms/pages/${id}`);
  revalidatePath("/cms/pages");
}

export async function deletePageAction(id: string) {
  await adminFetch(`/admin/cms/pages/${id}`, { method: "DELETE" });
  revalidatePath("/cms/pages");
  redirect("/cms/pages");
}
