import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { formatDate } from "@/lib/format";
import { buildMetadata } from "@/lib/metadata";
import { getUpdateBySlug, getUpdateSlugs } from "@/lib/updates";

type UpdatePostPageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await getUpdateSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: UpdatePostPageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = await getUpdateBySlug(slug);
  if (!post) {
    return buildMetadata("Update not found | MindSense AI", "The update post was not found.");
  }
  return buildMetadata(`${post.title} | MindSense AI`, post.summary);
}

export default async function UpdatePostPage({ params }: UpdatePostPageProps) {
  const { slug } = await params;
  const post = await getUpdateBySlug(slug);

  if (!post) notFound();

  return (
    <article className="section-space mx-auto max-w-3xl">
      <Link
        href="/updates"
        className="mb-4 inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
      >
        ← Back to updates
      </Link>
      <p className="text-xs uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">
        {formatDate(post.date)} • {post.author}
      </p>
      <h1 className="mt-2 text-4xl font-semibold tracking-tight text-ink-900 dark:text-white">{post.title}</h1>
      <p className="mt-3 text-base text-ink-600 dark:text-ink-300">{post.summary}</p>
      <div
        className="prose prose-slate mt-8 max-w-none dark:prose-invert prose-headings:font-semibold prose-a:text-accent-700 dark:prose-a:text-accent-300"
        dangerouslySetInnerHTML={{ __html: post.contentHtml }}
      />
    </article>
  );
}
