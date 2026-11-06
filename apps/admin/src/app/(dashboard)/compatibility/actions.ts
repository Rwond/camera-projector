"use server";

import { revalidatePath } from "next/cache";
import { adminFetch } from "@/lib/api";

export async function createCompatibilityRecordAction(formData: FormData) {
  const deviceModel = String(formData.get("deviceModel") ?? "");
  const accessoryModel = String(formData.get("accessoryModel") ?? "") || undefined;
  const osName = String(formData.get("osName") ?? "");
  const osVersion = String(formData.get("osVersion") ?? "") || undefined;
  const mode = String(formData.get("mode") ?? "");
  const feature = String(formData.get("feature") ?? "");
  const result = String(formData.get("result") ?? "");

  await adminFetch("/admin/compatibility", {
    method: "POST",
    body: JSON.stringify({ deviceModel, accessoryModel, osName, osVersion, mode, feature, result }),
  });

  revalidatePath("/compatibility");
}
