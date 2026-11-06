"use server";

import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

export async function createAccessoryAction(formData: FormData) {
  const serialNumber = String(formData.get("serialNumber") ?? "");
  const model = String(formData.get("model") ?? "");
  const firmwareVersion = String(formData.get("firmwareVersion") ?? "") || undefined;
  const batchNumber = String(formData.get("batchNumber") ?? "") || undefined;

  await adminFetch("/admin/accessories", {
    method: "POST",
    body: JSON.stringify({ serialNumber, model, firmwareVersion, batchNumber }),
  });

  revalidatePath("/accessories");
}
