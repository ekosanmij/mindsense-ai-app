import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { TrackedLink } from "@/components/tracked-link";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.trustTitle, siteConfig.metadata.trustDescription);

const trustCards = [
  {
    title: "Privacy",
    href: "/trust/privacy",
    points: siteConfig.trust.privacy,
  },
  {
    title: "Security",
    href: "/trust/security",
    points: siteConfig.trust.security,
  },
  {
    title: "Safety",
    href: "/trust/safety",
    points: siteConfig.trust.safety,
  },
  {
    title: "Data rights",
    href: "/trust/data-rights",
    points: siteConfig.trust.dataRights,
  },
];

export default function TrustPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Trust Center"
            title="Privacy, security, safety, and data rights"
            description="MindSense publishes practical trust commitments in plain language so users and partners can evaluate fit quickly."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          {trustCards.map((card) => (
            <article key={card.title} className="surface-card p-5">
              <h2 className="text-2xl font-semibold text-ink-900 dark:text-white">{card.title}</h2>
              <ul className="mt-3 space-y-1.5 text-sm text-ink-600 dark:text-ink-300">
                {card.points.map((point) => (
                  <li key={point} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{point}</span></li>
                ))}
              </ul>
              <TrackedLink
                href={card.href}
                className="mt-4 inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                View {card.title.toLowerCase()} details →
              </TrackedLink>
            </article>
          ))}
        </section>
      </Reveal>
    </div>
  );
}
