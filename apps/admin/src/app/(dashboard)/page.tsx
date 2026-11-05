import { getCurrentUser } from "@/lib/auth";

export default async function DashboardHomePage() {
  const user = await getCurrentUser();

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-semibold">Tableau de bord</h1>
      <p className="text-neutral-400">
        Connecté en tant que <span className="text-neutral-200">{user?.email}</span>.
      </p>
      <p className="text-neutral-500">
        Les droits affichés dépendent de votre rôle d&apos;administration, vérifié côté serveur à
        chaque action.
      </p>
    </div>
  );
}
