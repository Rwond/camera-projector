import "server-only";
import { redirect } from "next/navigation";
import { getAccessToken } from "./auth";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

/** Appelle l'API backend avec le jeton de la session courante. Redirige vers /login si aucun
 * jeton n'est présent ou si le backend le rejette (401) ; lève ApiError pour un refus RBAC (403)
 * ou toute autre erreur, à charge de l'appelant de l'afficher proprement. */
export async function adminFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = await getAccessToken();
  if (!token) {
    redirect("/login");
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      ...init.headers,
      Authorization: `Bearer ${token}`,
      ...(init.body ? { "Content-Type": "application/json" } : {}),
    },
    cache: "no-store",
  });

  if (res.status === 401) {
    redirect("/login");
  }
  if (!res.ok) {
    const body = await res.text();
    throw new ApiError(res.status, body || `Erreur ${res.status}`);
  }

  if (res.status === 204) {
    return undefined as T;
  }
  return res.json() as Promise<T>;
}

export { API_URL };
