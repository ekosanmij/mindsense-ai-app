import Link from "next/link";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.privacyTitle, siteConfig.metadata.privacyDescription);

const dataCollected = [
  "Device and health-adjacent signal summaries needed for readiness estimation",
  "Manual check-ins and protocol completion events",
  "Feature usage events used for product quality improvements",
];

const dataNotCollected = [
  "No claim of collecting unnecessary personal identifiers for ads",
  "No emergency-service monitoring claim",
  "No hidden data resale claim",
];

export default function PrivacyPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Privacy"
            title="Plain-English trust page"
            description="Use this page as the public baseline for privacy and data handling. Replace placeholders with legal-approved language."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Summary" title="What to know in 30 seconds" />
          <div className="surface-card p-5">
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {siteConfig.privacySummary.map((item) => (
                <li key={item} className="flex gap-2">
                  <span className="mt-1 text-accent-500">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">What data is collected</h2>
            <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {dataCollected.map((item) => (
                <li key={item} className="flex gap-2">
                  <span className="mt-1 text-accent-500">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </article>

          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">What data is not collected</h2>
            <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {dataNotCollected.map((item) => (
                <li key={item} className="flex gap-2">
                  <span className="mt-1 text-accent-500">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Storage and retention</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              Placeholder policy text: describe where user data is stored, retention durations, and deletion windows
              after account closure.
            </p>
          </article>

          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Export and delete controls</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              Placeholder policy text: describe export request flow, deletion request flow, and expected turnaround
              times.
            </p>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <div className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Privacy contact</h2>
            <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
              For privacy questions, contact{" "}
              <a className="text-accent-700 dark:text-accent-300" href={`mailto:${siteConfig.email}`}>
                {siteConfig.email}
              </a>
              .
            </p>
            <Link
              href={siteConfig.links.privacy}
              target="_blank"
              rel="noreferrer noopener"
              className="mt-4 inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
            >
              External policy link placeholder →
            </Link>
          </div>
        </section>
      </Reveal>
    </div>
  );
}
