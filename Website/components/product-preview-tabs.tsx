"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";

type PreviewItem = {
  id: string;
  title: string;
  image: string;
  bullets: string[];
};

type ProductPreviewTabsProps = {
  items: PreviewItem[];
};

export function ProductPreviewTabs({ items }: ProductPreviewTabsProps) {
  const [activeId, setActiveId] = useState(items[0]?.id ?? "");
  const active = items.find((item) => item.id === activeId) ?? items[0];

  if (!active) return null;

  return (
    <div className="rounded-xl2 border border-ink-200 bg-white p-4 shadow-card dark:border-ink-800 dark:bg-ink-900 md:p-6">
      <div className="mb-5 flex flex-wrap gap-2">
        {items.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => setActiveId(item.id)}
            className={`rounded-full px-4 py-2 text-sm font-medium transition ${
              item.id === active.id
                ? "bg-accent-500 text-white"
                : "bg-ink-100 text-ink-700 hover:bg-ink-200 dark:bg-ink-800 dark:text-ink-200 dark:hover:bg-ink-700"
            }`}
            aria-pressed={item.id === active.id}
          >
            {item.title}
          </button>
        ))}
      </div>

      <div className="grid gap-6 md:grid-cols-[1.1fr_1fr] md:items-center">
        <div className="relative overflow-hidden rounded-xl2 border border-ink-200 bg-ink-50 dark:border-ink-700 dark:bg-ink-950">
          <Image
            src={active.image}
            alt={`${active.title} preview`}
            width={1200}
            height={800}
            className="h-auto w-full"
            priority={false}
          />
        </div>

        <div>
          <h3 className="text-2xl font-semibold text-ink-900 dark:text-white">{active.title}</h3>
          <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
            {active.bullets.map((bullet) => (
              <li key={bullet} className="flex gap-2">
                <span className="mt-1 text-accent-500">●</span>
                <span>{bullet}</span>
              </li>
            ))}
          </ul>
          <Link
            href="/product"
            className="mt-4 inline-flex items-center text-sm font-semibold text-accent-700 transition hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
          >
            See more product details →
          </Link>
        </div>
      </div>
    </div>
  );
}
