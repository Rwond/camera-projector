"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

function parseBody(formData: FormData) {
  const raw = String(formData.get("bodyJson") ?? '{"blocks":[]}');
  return JSON.parse(raw);
}

export async function createArticleAction(formData: FormData) {
  const slug = String(formData.get("slug") ?? "");
  const locale = String(formData.get("locale") ?? "fr");
  const title = String(formData.get("title") ?? "");
  const category = String(formData.get("category") ?? "NEWS");
  const body = parseBody(formData);

  await adminFetch("/admin/cms/articles", {
    method: "POST",
    body: JSON.stringify({ slug, locale, title, category, body }),
  });

  revalidatePath("/cms/articles");
  redirect("/cms/articles");
}

export async function updateArticleAction(id: string, formData: FormData) {
  const title = String(formData.get("title") ?? "");
  const category = String(formData.get("category") ?? "NEWS");
  const body = parseBody(formData);

  await adminFetch(`/admin/cms/articles/${id}`, {
    method: "PATCH",
    body: JSON.stringify({ title, category, body }),
  });

  revalidatePath(`/cms/articles/${id}`);
  revalidatePath("/cms/articles");
}

export async function publishArticleAction(id: string) {
  await adminFetch(`/admin/cms/articles/${id}/publish`, { method: "POST" });
  revalidatePath(`/cms/articles/${id}`);
  revalidatePath("/cms/articles");
}

export async function unpublishArticleAction(id: string) {
  await adminFetch(`/admin/cms/articles/${id}/unpublish`, { method: "POST" });
  revalidatePath(`/cms/articles/${id}`);
  revalidatePath("/cms/articles");
}

export async function scheduleArticleAction(id: string, formData: FormData) {
  const publishAt = String(formData.get("publishAt") ?? "");
  await adminFetch(`/admin/cms/articles/${id}/schedule`, {
    method: "POST",
    body: JSON.stringify({ publishAt: new Date(publishAt).toISOString() }),
  });
  revalidatePath(`/cms/articles/${id}`);
  revalidatePath("/cms/articles");
}

export async function deleteArticleAction(id: string) {
  await adminFetch(`/admin/cms/articles/${id}`, { method: "DELETE" });
  revalidatePath("/cms/articles");
  redirect("/cms/articles");
}
