import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.privacyTitle, siteConfig.metadata.privacyDescription);

const collected = [
  "Wearable-adjacent readiness signals and check-ins used for guidance",
  "Protocol completion and impact responses used for personalized learning",
  "Product quality telemetry required to improve reliability",
];

const notCollected = [
  "No advertising profile creation posture",
  "No claim of selling identifiable personal data",
  "No emergency-service monitoring claim",
];

export default function TrustPrivacyPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Trust • Privacy"
            title="Plain-language data handling"
            description="MindSense collects only what is needed to support state estimates, recommendations, and protocol learning."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">What we collect</h2>
            <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {collected.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </article>
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">What we do not collect</h2>
            <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {notCollected.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Retention</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              Data retention follows operational necessity and user rights controls. Deletion requests are actioned within the stated support window.
            </p>
          </article>
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Privacy contact</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              For privacy questions or data-rights requests, contact <a className="text-accent-700 dark:text-accent-300" href={siteConfig.links.support}>{siteConfig.email}</a>.
            </p>
          </article>
        </section>
      </Reveal>
    </div>
  );
}
