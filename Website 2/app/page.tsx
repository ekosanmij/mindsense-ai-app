import Image from "next/image";
import { CtaBand } from "@/components/cta-band";
import { InteractiveLoopDemo } from "@/components/interactive-loop-demo";
import { MetricTiles } from "@/components/metric-tiles";
import { ProductPreviewTabs } from "@/components/product-preview-tabs";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { TrackedLink } from "@/components/tracked-link";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.homeTitle, siteConfig.metadata.homeDescription);

const outcomeValues: Record<string, string> = {
  Clarity: "Know your state",
  Action: "Run one protocol",
  Consistency: "Compound readiness",
};

export default function HomePage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space grid gap-8 md:grid-cols-[1.05fr_0.95fr] md:items-center">
          <div>
            <span className="chip">Readiness • Load • Consistency</span>
            <h1 className="mt-4 text-4xl font-semibold tracking-tight text-ink-900 md:text-6xl dark:text-white">
              {siteConfig.hero.headline}
            </h1>
            <p className="mt-4 max-w-2xl text-base text-ink-600 md:text-lg dark:text-ink-300">
              {siteConfig.hero.subheadline}
            </p>
            <p className="mt-3 text-sm text-ink-500 dark:text-ink-400">{siteConfig.hero.trustLine}</p>

            <div className="mt-6 flex flex-wrap gap-3">
              <TrackedLink
                href={siteConfig.links.getApp}
                eventName="cta_get_app_clicked"
                eventPayload={{ source: "hero_primary" }}
                className="inline-flex items-center justify-center rounded-full bg-accent-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-accent-600"
              >
                Get the app
              </TrackedLink>
              <TrackedLink
                href={siteConfig.links.bookPilot}
                eventName="cta_book_pilot_clicked"
                eventPayload={{ source: "hero_secondary" }}
                className="inline-flex items-center justify-center rounded-full border border-ink-300 px-5 py-2.5 text-sm font-semibold text-ink-900 transition hover:border-accent-500 hover:text-accent-700 dark:border-ink-700 dark:text-ink-100 dark:hover:border-accent-500 dark:hover:text-accent-300"
              >
                Book a pilot
              </TrackedLink>
            </div>

            <div className="mt-4 flex flex-wrap items-center gap-4 text-sm">
              <TrackedLink
                href={siteConfig.links.joinBeta}
                className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                Join beta
              </TrackedLink>
              <TrackedLink
                href={siteConfig.links.requestDeck}
                className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                Request investor deck
              </TrackedLink>
            </div>
          </div>

          <div className="app-frame w-full max-w-[380px] animate-float p-2">
            <Image
              src="/screens/today-overview.svg"
              alt="MindSense Today screen in device frame"
              width={900}
              height={1900}
              className="h-auto w-full rounded-[1.8rem]"
              priority
            />
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section>
          <MetricTiles
            items={siteConfig.outcomes.map((item) => ({
              label: item.title,
              value: outcomeValues[item.title] ?? item.title,
              detail: item.description,
            }))}
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <InteractiveLoopDemo />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Product Loop"
            title="Today → Regulate → Data"
            description="The loop is intentionally simple: understand state, execute one protocol, and learn from outcomes."
          />
          <div className="grid gap-4 md:grid-cols-3">
            {siteConfig.productPillars.map((pillar) => (
              <article key={pillar.title} className="surface-card p-5">
                <h2 className="text-xl font-semibold text-ink-900 dark:text-white">{pillar.title}</h2>
                <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{pillar.summary}</p>
              </article>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Product Preview"
            title="See the core surfaces in motion"
            description="Switch between Today, Regulate, and Data previews to understand the end-to-end experience."
          />
          <ProductPreviewTabs items={siteConfig.productPreview} />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Why it is different"
            title="Designed for decision quality under stress"
            description="MindSense emphasizes practical action and transparent reasoning rather than opaque wellness scoring."
          />
          <div className="grid gap-3 md:grid-cols-2">
            {siteConfig.differentiators.map((line) => (
              <div
                key={line}
                className="surface-card flex items-start gap-3 rounded-xl2 p-4 text-sm text-ink-700 dark:text-ink-200"
              >
                <span className="mt-0.5 text-accent-500">✓</span>
                <span>{line}</span>
              </div>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Protocols"
            title="Three protocol paths for real contexts"
            description="Each protocol is designed for a specific state profile and feeds learning back into future recommendations."
          />
          <div className="grid gap-4 md:grid-cols-3">
            {siteConfig.protocols.map((protocol) => (
              <article key={protocol.name} className="surface-card p-5">
                <h3 className="text-xl font-semibold text-ink-900 dark:text-white">{protocol.name}</h3>
                <p className="mt-1 text-sm text-accent-700 dark:text-accent-300">{protocol.duration}</p>
                <p className="mt-3 text-sm text-ink-600 dark:text-ink-300"><span className="font-semibold">When:</span> {protocol.when}</p>
                <p className="mt-2 text-sm text-ink-600 dark:text-ink-300"><span className="font-semibold">Immediate:</span> {protocol.immediate}</p>
              </article>
            ))}
          </div>
          <TrackedLink
            href="/protocols"
            className="inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
          >
            Explore all protocols →
          </TrackedLink>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Trust"
            title="Built for transparency and safety"
            description="Privacy, security, safety boundaries, and data rights are part of the product experience, not legal afterthoughts."
          />
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {Object.entries(siteConfig.trust).map(([key, points]) => (
              <article key={key} className="surface-card p-4">
                <h3 className="text-base font-semibold capitalize text-ink-900 dark:text-white">{key.replace(/([A-Z])/g, " $1")}</h3>
                <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{points[0]}</p>
              </article>
            ))}
          </div>
          <TrackedLink
            href="/trust"
            className="inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
          >
            View Trust Center →
          </TrackedLink>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-accent-700 dark:text-accent-300">For individuals</p>
            <h2 className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">Get guided support today</h2>
            <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
              Start with daily state clarity, one next protocol, and trend learning that gets sharper over time.
            </p>
            <div className="mt-4 flex gap-2">
              <TrackedLink
                href={siteConfig.links.getApp}
                eventName="cta_get_app_clicked"
                eventPayload={{ source: "audience_lane_individual" }}
                className="inline-flex rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white"
              >
                Get the app
              </TrackedLink>
              <TrackedLink
                href={siteConfig.links.joinBeta}
                className="inline-flex rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 dark:border-ink-700 dark:text-ink-100"
              >
                Join beta
              </TrackedLink>
            </div>
          </article>

          <article className="surface-card p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-accent-700 dark:text-accent-300">For teams and investors</p>
            <h2 className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">Evaluate a pilot pathway</h2>
            <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
              Review pilot structure, outcomes framework, trust model, and implementation support for real-world deployment.
            </p>
            <div className="mt-4 flex gap-2">
              <TrackedLink
                href={siteConfig.links.bookPilot}
                eventName="cta_book_pilot_clicked"
                eventPayload={{ source: "audience_lane_team" }}
                className="inline-flex rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 dark:border-ink-700 dark:text-ink-100"
              >
                Book pilot
              </TrackedLink>
              <TrackedLink
                href={siteConfig.links.requestDeck}
                className="inline-flex rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white"
              >
                Request deck
              </TrackedLink>
            </div>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <CtaBand
            title="From signal awareness to reliable action"
            subtitle="Get started as an individual or book a pilot to evaluate deployment across your team."
          />
        </section>
      </Reveal>
    </div>
  );
}
