import "server-only";
import { cookies } from "next/headers";

const ACCESS_TOKEN_COOKIE = "swvertex_admin_access_token";
const REFRESH_TOKEN_COOKIE = "swvertex_admin_refresh_token";

const COOKIE_OPTIONS = {
  httpOnly: true,
  sameSite: "lax" as const,
  secure: process.env.NODE_ENV === "production",
  path: "/",
};

export async function setSessionCookies(accessToken: string, refreshToken: string) {
  const store = await cookies();
  store.set(ACCESS_TOKEN_COOKIE, accessToken, COOKIE_OPTIONS);
  store.set(REFRESH_TOKEN_COOKIE, refreshToken, COOKIE_OPTIONS);
}

export async function clearSessionCookies() {
  const store = await cookies();
  store.delete(ACCESS_TOKEN_COOKIE);
  store.delete(REFRESH_TOKEN_COOKIE);
}

export async function getAccessToken(): Promise<string | undefined> {
  const store = await cookies();
  return store.get(ACCESS_TOKEN_COOKIE)?.value;
}

export interface CurrentUser {
  id: string;
  email: string;
}

/** Décodage seul, sans vérification de signature : affichage uniquement. Le backend revérifie
 * le jeton à chaque requête réelle — ceci ne sert jamais de contrôle d'accès. */
export function decodeAccessToken(token: string): CurrentUser | null {
  try {
    const payload = token.split(".")[1];
    const json = Buffer.from(payload, "base64url").toString("utf8");
    const data = JSON.parse(json) as { sub: string; email: string };
    return { id: data.sub, email: data.email };
  } catch {
    return null;
  }
}

export async function getCurrentUser(): Promise<CurrentUser | null> {
  const token = await getAccessToken();
  if (!token) return null;
  return decodeAccessToken(token);
}
