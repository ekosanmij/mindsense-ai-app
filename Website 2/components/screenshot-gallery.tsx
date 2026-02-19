"use client";

import Image from "next/image";
import { useEffect, useMemo, useState } from "react";

export type ScreenshotItem = {
  src: string;
  title: string;
  caption: string;
};

type ScreenshotGalleryProps = {
  items: ScreenshotItem[];
  columns?: 2 | 3;
};

export function ScreenshotGallery({ items, columns = 3 }: ScreenshotGalleryProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [touchStartX, setTouchStartX] = useState<number | null>(null);
  const activeItem = useMemo(
    () => (activeIndex === null ? null : items[Math.max(0, Math.min(items.length - 1, activeIndex))]),
    [activeIndex, items],
  );

  useEffect(() => {
    if (activeIndex === null) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setActiveIndex(null);
      if (event.key === "ArrowRight") setActiveIndex((prev) => (prev === null ? 0 : (prev + 1) % items.length));
      if (event.key === "ArrowLeft")
        setActiveIndex((prev) => (prev === null ? 0 : (prev - 1 + items.length) % items.length));
    };

    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", onKeyDown);

    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [activeIndex, items.length]);

  return (
    <>
      <div className={`grid gap-4 ${columns === 2 ? "md:grid-cols-2" : "md:grid-cols-2 xl:grid-cols-3"}`}>
        {items.map((item, index) => (
          <button
            key={item.src}
            type="button"
            className="group overflow-hidden rounded-xl2 border border-ink-200 bg-white text-left shadow-card transition hover:-translate-y-0.5 hover:border-accent-300 dark:border-ink-800 dark:bg-ink-900 dark:hover:border-accent-700"
            onClick={() => setActiveIndex(index)}
          >
            <Image src={item.src} alt={item.title} width={1200} height={900} className="h-auto w-full" />
            <div className="p-4">
              <p className="text-base font-semibold text-ink-900 dark:text-white">{item.title}</p>
              <p className="mt-1 text-sm text-ink-600 dark:text-ink-300">{item.caption}</p>
            </div>
          </button>
        ))}
      </div>

      {activeItem && activeIndex !== null ? (
        <div
          className="fixed inset-0 z-[60] bg-ink-950/90 p-4 backdrop-blur-sm"
          role="dialog"
          aria-modal="true"
          aria-label={`${activeItem.title} screenshot viewer`}
          onClick={() => setActiveIndex(null)}
        >
          <div className="mx-auto flex h-full w-full max-w-5xl flex-col justify-center">
            <div
              className="relative overflow-hidden rounded-3xl border border-white/20 bg-ink-950/80"
              onClick={(event) => event.stopPropagation()}
              onTouchStart={(event) => setTouchStartX(event.touches[0]?.clientX ?? null)}
              onTouchEnd={(event) => {
                if (touchStartX === null) return;
                const endX = event.changedTouches[0]?.clientX ?? touchStartX;
                const diff = endX - touchStartX;
                if (Math.abs(diff) > 42) {
                  if (diff < 0) {
                    setActiveIndex((prev) => (prev === null ? 0 : (prev + 1) % items.length));
                  } else {
                    setActiveIndex((prev) => (prev === null ? 0 : (prev - 1 + items.length) % items.length));
                  }
                }
                setTouchStartX(null);
              }}
            >
              <Image
                src={activeItem.src}
                alt={activeItem.title}
                width={1680}
                height={1120}
                className="h-auto w-full"
                priority
              />
              <div className="flex items-center justify-between gap-4 border-t border-white/15 px-4 py-3 text-white">
                <div>
                  <p className="font-medium">{activeItem.title}</p>
                  <p className="text-sm text-white/80">{activeItem.caption}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    type="button"
                    className="rounded-full border border-white/35 px-3 py-1 text-sm"
                    onClick={() => setActiveIndex((prev) => (prev === null ? 0 : (prev - 1 + items.length) % items.length))}
                  >
                    Prev
                  </button>
                  <button
                    type="button"
                    className="rounded-full border border-white/35 px-3 py-1 text-sm"
                    onClick={() => setActiveIndex((prev) => (prev === null ? 0 : (prev + 1) % items.length))}
                  >
                    Next
                  </button>
                  <button
                    type="button"
                    className="rounded-full border border-white/35 px-3 py-1 text-sm"
                    onClick={() => setActiveIndex(null)}
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
