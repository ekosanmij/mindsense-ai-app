import { TrackedLink } from "@/components/tracked-link";
import { siteConfig } from "@/lib/site-config";

type CtaBandProps = {
  title: string;
  subtitle: string;
};

export function CtaBand({ title, subtitle }: CtaBandProps) {
  return (
    <section className="rounded-3xl border border-ink-200 bg-gradient-to-br from-white via-accent-50 to-white p-8 shadow-card dark:border-ink-700 dark:from-ink-900 dark:via-accent-950/40 dark:to-ink-900">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="text-2xl font-semibold text-ink-900 dark:text-white">{title}</h2>
          <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{subtitle}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <TrackedLink
            href={siteConfig.links.bookPilot}
            eventName="cta_book_pilot_clicked"
            eventPayload={{ source: "cta_band" }}
            className="inline-flex items-center justify-center rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 transition hover:border-accent-400 hover:text-accent-700 dark:border-ink-600 dark:text-ink-100 dark:hover:border-accent-500 dark:hover:text-accent-300"
          >
            Book a pilot
          </TrackedLink>
          <TrackedLink
            href={siteConfig.links.getApp}
            eventName="cta_get_app_clicked"
            eventPayload={{ source: "cta_band" }}
            className="inline-flex items-center justify-center rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600"
          >
            Get the app
          </TrackedLink>
        </div>
      </div>
    </section>
  );
}
