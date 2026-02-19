import fs from "node:fs/promises";
import path from "node:path";
import matter from "gray-matter";
import { remark } from "remark";
import gfm from "remark-gfm";
import html from "remark-html";

const updatesDir = path.join(process.cwd(), "content", "updates");

export type UpdateSummary = {
  slug: string;
  title: string;
  date: string;
  summary: string;
  author: string;
};

export type UpdatePost = UpdateSummary & {
  contentHtml: string;
};

async function getAllFilenames(): Promise<string[]> {
  const files = await fs.readdir(updatesDir);
  return files.filter((file) => file.endsWith(".md"));
}

function getSlugFromFilename(file: string): string {
  return file.replace(/\.md$/, "");
}

export async function getUpdateSummaries(): Promise<UpdateSummary[]> {
  const files = await getAllFilenames();

  const summaries = await Promise.all(
    files.map(async (file) => {
      const fullPath = path.join(updatesDir, file);
      const raw = await fs.readFile(fullPath, "utf8");
      const parsed = matter(raw);
      const slug = getSlugFromFilename(file);

      return {
        slug,
        title: String(parsed.data.title ?? slug),
        date: String(parsed.data.date ?? ""),
        summary: String(parsed.data.summary ?? ""),
        author: String(parsed.data.author ?? "MindSense Team"),
      };
    }),
  );

  return summaries.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getUpdateBySlug(slug: string): Promise<UpdatePost | null> {
  const fullPath = path.join(updatesDir, `${slug}.md`);

  try {
    const raw = await fs.readFile(fullPath, "utf8");
    const parsed = matter(raw);
    const processed = await remark().use(gfm).use(html).process(parsed.content);

    return {
      slug,
      title: String(parsed.data.title ?? slug),
      date: String(parsed.data.date ?? ""),
      summary: String(parsed.data.summary ?? ""),
      author: String(parsed.data.author ?? "MindSense Team"),
      contentHtml: processed.toString(),
    };
  } catch {
    return null;
  }
}

export async function getUpdateSlugs(): Promise<string[]> {
  const files = await getAllFilenames();
  return files.map(getSlugFromFilename);
}
