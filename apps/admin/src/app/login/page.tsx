"use client";

import { useActionState } from "react";
import { loginAction, type LoginState } from "./actions";

const initialState: LoginState = {};

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(loginAction, initialState);

  return (
    <div className="flex min-h-screen items-center justify-center bg-neutral-950 px-6">
      <form action={formAction} className="w-full max-w-sm rounded-xl border border-neutral-800 bg-neutral-900 p-8">
        <h1 className="mb-6 text-xl font-semibold text-neutral-100">SWVERTEX — Administration</h1>
        <div className="flex flex-col gap-4">
          <label className="flex flex-col gap-1 text-sm text-neutral-300">
            E-mail
            <input
              name="email"
              type="email"
              required
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2 text-neutral-100"
            />
          </label>
          <label className="flex flex-col gap-1 text-sm text-neutral-300">
            Mot de passe
            <input
              name="password"
              type="password"
              required
              className="rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2 text-neutral-100"
            />
          </label>
          {state.error && <p className="text-sm text-red-400">{state.error}</p>}
          <button
            type="submit"
            disabled={pending}
            className="mt-2 rounded-md bg-neutral-100 px-4 py-2 text-sm font-medium text-neutral-900 disabled:opacity-50"
          >
            {pending ? "Connexion..." : "Se connecter"}
          </button>
        </div>
      </form>
    </div>
  );
}
