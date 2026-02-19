import Link from "next/link";
import { footerNavLinks, siteConfig } from "@/lib/site-config";

export function SiteFooter() {
  return (
    <footer className="border-t border-ink-200 bg-white/80 py-10 dark:border-ink-800 dark:bg-ink-950/85">
      <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 md:grid-cols-[1.6fr_1fr_1fr] md:px-6">
        <div className="space-y-4">
          <div className="inline-flex items-center gap-2">
            <img src="/brand/logo-icon-dark.svg" alt="" className="h-7 w-7 rounded-sm dark:hidden" />
            <img src="/brand/logo-icon-light.svg" alt="" className="hidden h-7 w-7 rounded-sm dark:block" />
            <span className="font-semibold text-ink-900 dark:text-ink-100">{siteConfig.appName}</span>
          </div>
          <p className="max-w-sm text-sm text-ink-600 dark:text-ink-300">{siteConfig.description}</p>
          <p className="text-sm text-ink-600 dark:text-ink-300">
            Contact:{" "}
            <a href={`mailto:${siteConfig.email}`} className="text-accent-700 dark:text-accent-300">
              {siteConfig.email}
            </a>
          </p>
          <p className="text-xs text-ink-500 dark:text-ink-400">
            MindSense AI is a wellness support product and not an emergency service.
          </p>
        </div>

        <div>
          <h2 className="mb-2 text-sm font-semibold text-ink-900 dark:text-ink-100">Pages</h2>
          <ul className="space-y-1.5">
            {footerNavLinks.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="text-sm text-ink-600 transition hover:text-accent-700 dark:text-ink-300 dark:hover:text-accent-300"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h2 className="mb-2 text-sm font-semibold text-ink-900 dark:text-ink-100">Social</h2>
          <ul className="space-y-1.5">
            {siteConfig.socials.map((social) => (
              <li key={social.label}>
                <a
                  href={social.href}
                  target="_blank"
                  rel="noreferrer noopener"
                  className="text-sm text-ink-600 transition hover:text-accent-700 dark:text-ink-300 dark:hover:text-accent-300"
                >
                  {social.label}
                </a>
              </li>
            ))}
          </ul>
          <p className="mt-4 text-xs text-ink-500 dark:text-ink-400">
            © {new Date().getFullYear()} {siteConfig.companyName}
          </p>
        </div>
      </div>
    </footer>
  );
}
