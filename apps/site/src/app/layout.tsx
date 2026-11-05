import type { Metadata } from "next";
import Link from "next/link";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "SWVERTEX CAMERA PROJECTOR",
  description:
    "Projection multi-mode depuis votre téléphone : lentille optique, module USB-C, projecteur Wi-Fi.",
};

const NAV_LINKS = [
  { href: "/", label: "Accueil" },
  { href: "/compatibilite", label: "Compatibilité" },
  { href: "/actualites", label: "Actualités" },
  { href: "/guides", label: "Guides & FAQ" },
];

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="fr"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-white text-neutral-900 dark:bg-neutral-950 dark:text-neutral-100">
        <header className="border-b border-neutral-200 dark:border-neutral-800">
          <nav className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
            <Link href="/" className="text-lg font-semibold tracking-tight">
              SWVERTEX
            </Link>
            <ul className="flex gap-6 text-sm">
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="hover:underline">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
        </header>
        <main className="mx-auto w-full max-w-5xl flex-1 px-6 py-10">{children}</main>
        <footer className="border-t border-neutral-200 px-6 py-6 text-center text-xs text-neutral-500 dark:border-neutral-800">
          SWVERTEX CAMERA PROJECTOR — site de présentation
        </footer>
      </body>
    </html>
  );
}
