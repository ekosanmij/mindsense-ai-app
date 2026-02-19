import Link from "next/link";
import { CtaBand } from "@/components/cta-band";
import { Reveal } from "@/components/reveal";
import { RoadmapBoard } from "@/components/roadmap-board";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.teamsTitle, siteConfig.metadata.teamsDescription);

export default function ForTeamsPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="For Teams"
            title="Deploy MindSense AI as a focused pilot"
            description="For performance teams, startups, clinics, and enterprise wellbeing programs."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Who It Is For" title="Primary partner profiles" />
          <div className="grid gap-3 md:grid-cols-2">
            {siteConfig.teams.forWho.map((item) => (
              <div
                key={item}
                className="rounded-2xl border border-ink-200 bg-white px-4 py-3 text-sm text-ink-700 shadow-card dark:border-ink-800 dark:bg-ink-900 dark:text-ink-200"
              >
                {item}
              </div>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Value" title="Business outcomes in practical language" />
          <div className="grid gap-4 md:grid-cols-2">
            {siteConfig.teams.valueProps.map((item) => (
              <article key={item} className="surface-card p-5">
                <p className="text-sm text-ink-700 dark:text-ink-200">{item}</p>
              </article>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Deployment Model" title="Structured 4–6 week pilot program" />
          <div className="surface-card p-5">
            <ol className="space-y-3">
              {siteConfig.teams.pilot.map((phase) => (
                <li key={phase} className="rounded-xl border border-ink-200 bg-ink-50 px-3 py-2 text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-200">
                  {phase}
                </li>
              ))}
            </ol>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Pilot Package" title="What a client receives in 30 days" />
          <div className="grid gap-3 md:grid-cols-2">
            {siteConfig.pilotPackage.map((item) => (
              <div
                key={item}
                className="rounded-2xl border border-ink-200 bg-white px-4 py-3 text-sm text-ink-700 shadow-card dark:border-ink-800 dark:bg-ink-900 dark:text-ink-200"
              >
                {item}
              </div>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Roadmap" title="Now, next, and later" />
          <RoadmapBoard
            now={siteConfig.roadmap.now}
            next={siteConfig.roadmap.next}
            later={siteConfig.roadmap.later}
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Security & Privacy" title="Trust-focused implementation" />
          <div className="surface-card p-5">
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {siteConfig.privacySummary.map((item) => (
                <li key={item} className="flex gap-2">
                  <span className="mt-1 text-accent-500">•</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
            <Link
              href="/privacy"
              className="mt-4 inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
            >
              View privacy details →
            </Link>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <CtaBand
            title="Book a pilot call"
            subtitle="We will align on use case, pilot metrics, onboarding process, and reporting structure."
          />
        </section>
      </Reveal>
    </div>
  );
}
