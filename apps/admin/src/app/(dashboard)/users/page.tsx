import { adminFetch, ApiError } from "@/lib/api";
import { ADMIN_ROLES, type AdminUser } from "@/lib/types";
import { updateRoleAction } from "./actions";

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ email?: string }>;
}) {
  const { email } = await searchParams;

  let users: AdminUser[] = [];
  let accessDenied = false;

  try {
    users = await adminFetch<AdminUser[]>(`/admin/users${email ? `?email=${encodeURIComponent(email)}` : ""}`);
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      accessDenied = true;
    } else {
      throw error;
    }
  }

  if (accessDenied) {
    return <p className="text-neutral-400">Votre rôle ne vous donne pas accès à la liste des comptes.</p>;
  }

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-semibold">Comptes & rôles</h1>
      <p className="text-sm text-neutral-500">
        Seul un Super Admin peut accorder ou retirer un rôle d&apos;administration — une tentative
        par un autre rôle est refusée côté serveur.
      </p>

      <form method="get" className="flex gap-2">
        <input
          name="email"
          defaultValue={email ?? ""}
          placeholder="Rechercher par e-mail"
          className="flex-1 rounded-md border border-neutral-700 bg-neutral-800 px-3 py-2 text-sm"
        />
        <button type="submit" className="rounded-md border border-neutral-700 px-4 py-2 text-sm text-neutral-200">
          Rechercher
        </button>
      </form>

      {users.length === 0 ? (
        <p className="text-neutral-500">Aucun compte trouvé.</p>
      ) : (
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-neutral-800 text-neutral-400">
              <th className="py-2 pr-4 font-medium">E-mail</th>
              <th className="py-2 pr-4 font-medium">Statut</th>
              <th className="py-2 pr-4 font-medium">Rôle admin</th>
              <th className="py-2 pr-4 font-medium"></th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => {
              const update = updateRoleAction.bind(null, user.id);
              return (
                <tr key={user.id} className="border-b border-neutral-900">
                  <td className="py-2 pr-4">{user.email}</td>
                  <td className="py-2 pr-4">{user.status}</td>
                  <td className="py-2 pr-4">
                    <form action={update} className="flex gap-2">
                      <select
                        name="adminRole"
                        defaultValue={user.adminRole ?? ""}
                        className="rounded-md border border-neutral-700 bg-neutral-800 px-2 py-1"
                      >
                        <option value="">— Aucun —</option>
                        {ADMIN_ROLES.map((role) => (
                          <option key={role} value={role}>
                            {role}
                          </option>
                        ))}
                      </select>
                      <button
                        type="submit"
                        className="rounded-md border border-neutral-700 px-3 py-1 text-neutral-200"
                      >
                        Mettre à jour
                      </button>
                    </form>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}
