import Link from "next/link";
import { listArticles } from "@/lib/api";

export default async function GuidesPage() {
  const [guides, faqs] = await Promise.all([
    listArticles("fr", "GUIDE"),
    listArticles("fr", "FAQ"),
  ]);

  return (
    <div className="flex flex-col gap-10">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Guides & FAQ</h1>
        <p className="mt-2 text-neutral-600 dark:text-neutral-400">
          Tutoriels de prise en main et questions fréquentes.
        </p>
      </div>

      <section className="flex flex-col gap-4">
        <h2 className="text-xl font-semibold">Guides</h2>
        {guides.length === 0 ? (
          <p className="text-neutral-500">Aucun guide publié pour le moment.</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {guides.map((guide) => (
              <li key={guide.id}>
                <Link href={`/guides/${guide.slug}`} className="hover:underline">
                  {guide.title}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="text-xl font-semibold">FAQ</h2>
        {faqs.length === 0 ? (
          <p className="text-neutral-500">Aucune question fréquente publiée pour le moment.</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {faqs.map((faq) => (
              <li key={faq.id}>
                <Link href={`/guides/${faq.slug}`} className="hover:underline">
                  {faq.title}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
