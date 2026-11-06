import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { logoutAction } from "../actions";

const NAV_LINKS = [
  { href: "/", label: "Tableau de bord" },
  { href: "/cms/pages", label: "Pages" },
  { href: "/cms/articles", label: "Articles" },
  { href: "/cms/media", label: "Médias" },
  { href: "/support", label: "Support" },
  { href: "/audit-log", label: "Journal d'audit" },
];

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-neutral-800">
        <nav className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-8">
            <span className="text-lg font-semibold tracking-tight">SWVERTEX Admin</span>
            <ul className="flex gap-6 text-sm text-neutral-300">
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="hover:text-white hover:underline">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div className="flex items-center gap-4 text-sm text-neutral-400">
            {user && <span>{user.email}</span>}
            <form action={logoutAction}>
              <button type="submit" className="hover:text-white hover:underline">
                Déconnexion
              </button>
            </form>
          </div>
        </nav>
      </header>
      <main className="mx-auto w-full max-w-5xl flex-1 px-6 py-10">{children}</main>
    </div>
  );
}
