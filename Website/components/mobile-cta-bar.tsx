import Link from "next/link";
import { siteConfig } from "@/lib/site-config";

export function MobileCtaBar() {
  return (
    <div className="fixed inset-x-0 bottom-0 z-40 border-t border-ink-200 bg-white/95 px-4 py-3 shadow-card backdrop-blur md:hidden dark:border-ink-800 dark:bg-ink-950/95">
      <div className="mx-auto flex w-full max-w-6xl items-center gap-2">
        <Link
          href={siteConfig.links.bookDemo}
          target="_blank"
          rel="noreferrer noopener"
          className="inline-flex flex-1 items-center justify-center rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white"
        >
          Book Demo
        </Link>
        <Link
          href="/contact"
          className="inline-flex flex-1 items-center justify-center rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 dark:border-ink-700 dark:text-ink-100"
        >
          Join Waitlist
        </Link>
      </div>
    </div>
  );
}
