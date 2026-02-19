import Link from "next/link";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { formatDate } from "@/lib/format";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";
import { getUpdateSummaries } from "@/lib/updates";

export const metadata = buildMetadata(siteConfig.metadata.updatesTitle, siteConfig.metadata.updatesDescription);

export default async function UpdatesPage() {
  const posts = await getUpdateSummaries();

  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Updates"
            title="Release notes and changelog"
            description="Posts are loaded from markdown files in /content/updates."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-4">
          {posts.map((post) => (
            <article key={post.slug} className="surface-card p-5">
              <p className="text-xs uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">
                {formatDate(post.date)} • {post.author}
              </p>
              <h2 className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">{post.title}</h2>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{post.summary}</p>
              <Link
                href={`/updates/${post.slug}`}
                className="mt-3 inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                Read update →
              </Link>
            </article>
          ))}
        </section>
      </Reveal>
    </div>
  );
}
