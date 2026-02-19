"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { ThemeToggle } from "@/components/theme-toggle";
import { TrackedLink } from "@/components/tracked-link";
import { siteConfig, topNavLinks } from "@/lib/site-config";

export function SiteHeader() {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 border-b border-ink-200/70 bg-white/80 backdrop-blur supports-[backdrop-filter]:bg-white/65 dark:border-ink-800 dark:bg-ink-950/80 dark:supports-[backdrop-filter]:bg-ink-950/55">
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-4 py-3 md:px-6">
        <Link href="/" className="inline-flex items-center gap-2 font-semibold text-ink-900 dark:text-ink-50">
          <Image src="/brand/logo-icon-dark.svg" alt="" width={28} height={28} className="rounded-sm dark:hidden" />
          <Image
            src="/brand/logo-icon-light.svg"
            alt=""
            width={28}
            height={28}
            className="hidden rounded-sm dark:block"
          />
          <span>{siteConfig.appName}</span>
        </Link>

        <div className="hidden items-center gap-2 md:flex">
          <nav className="flex items-center gap-1">
            {topNavLinks.map((item) => {
              const active = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`rounded-full px-3 py-2 text-sm transition ${
                    active
                      ? "bg-accent-100 text-accent-900 dark:bg-accent-900/50 dark:text-accent-100"
                      : "text-ink-700 hover:bg-ink-100 hover:text-ink-900 dark:text-ink-200 dark:hover:bg-ink-900 dark:hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>

          <TrackedLink
            href={siteConfig.links.bookPilot}
            eventName="cta_book_pilot_clicked"
            eventPayload={{ source: "header" }}
            className="rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 transition hover:border-accent-400 hover:text-accent-700 dark:border-ink-700 dark:text-ink-100 dark:hover:border-accent-500 dark:hover:text-accent-300"
          >
            Book a pilot
          </TrackedLink>
          <TrackedLink
            href={siteConfig.links.getApp}
            eventName="cta_get_app_clicked"
            eventPayload={{ source: "header" }}
            className="rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600"
          >
            Get the app
          </TrackedLink>
          <ThemeToggle />
        </div>

        <div className="flex items-center gap-2 md:hidden">
          <ThemeToggle />
          <button
            type="button"
            aria-expanded={menuOpen}
            aria-controls="mobile-nav"
            onClick={() => setMenuOpen((prev) => !prev)}
            className="rounded-full border border-ink-200 bg-white px-3 py-2 text-sm text-ink-800 dark:border-ink-700 dark:bg-ink-900 dark:text-ink-100"
          >
            Menu
          </button>
        </div>
      </div>

      <div
        id="mobile-nav"
        className={`border-t border-ink-200/70 bg-white px-4 py-3 dark:border-ink-800 dark:bg-ink-950 md:hidden ${
          menuOpen ? "block" : "hidden"
        }`}
      >
        <nav className="grid gap-1">
          {topNavLinks.map((item) => {
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMenuOpen(false)}
                className={`rounded-lg px-3 py-2 text-sm ${
                  active
                    ? "bg-accent-100 text-accent-900 dark:bg-accent-900/50 dark:text-accent-100"
                    : "text-ink-700 dark:text-ink-200"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
          <TrackedLink
            href={siteConfig.links.bookPilot}
            eventName="cta_book_pilot_clicked"
            eventPayload={{ source: "mobile_menu" }}
            onClick={() => setMenuOpen(false)}
            className="mt-2 inline-flex items-center justify-center rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 dark:border-ink-700 dark:text-ink-100"
          >
            Book a pilot
          </TrackedLink>
          <TrackedLink
            href={siteConfig.links.getApp}
            eventName="cta_get_app_clicked"
            eventPayload={{ source: "mobile_menu" }}
            onClick={() => setMenuOpen(false)}
            className="inline-flex items-center justify-center rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white"
          >
            Get the app
          </TrackedLink>
        </nav>
      </div>
    </header>
  );
}
