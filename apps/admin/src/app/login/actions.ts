"use server";

import { redirect } from "next/navigation";
import { setSessionCookies } from "@/lib/auth";
import { API_URL } from "@/lib/api";

export interface LoginState {
  error?: string;
}

export async function loginAction(_prevState: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const res = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
    cache: "no-store",
  });

  if (!res.ok) {
    return { error: "Identifiants invalides." };
  }

  const { accessToken, refreshToken } = (await res.json()) as {
    accessToken: string;
    refreshToken: string;
  };
  await setSessionCookies(accessToken, refreshToken);
  redirect("/");
}
