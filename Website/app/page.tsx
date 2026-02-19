import Image from "next/image";
import Link from "next/link";
import { CtaBand } from "@/components/cta-band";
import { LeadForm } from "@/components/lead-form";
import { MetricTiles } from "@/components/metric-tiles";
import { ProductPreviewTabs } from "@/components/product-preview-tabs";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.homeTitle, siteConfig.metadata.homeDescription);

export default function HomePage() {
  const outcomeValues: Record<string, string> = {
    Clarity: "Know your state",
    Action: "Run a protocol",
    Consistency: "Compound over time",
  };

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
              <Link
                href={siteConfig.links.bookDemo}
                target="_blank"
                rel="noreferrer noopener"
                className="inline-flex items-center justify-center rounded-full bg-accent-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-accent-600"
              >
                Book a demo
              </Link>
              <Link
                href="/contact"
                className="inline-flex items-center justify-center rounded-full border border-ink-300 px-5 py-2.5 text-sm font-semibold text-ink-900 transition hover:border-accent-500 hover:text-accent-700 dark:border-ink-700 dark:text-ink-100 dark:hover:border-accent-500 dark:hover:text-accent-300"
              >
                Join waitlist
              </Link>
            </div>
            <div className="mt-3 flex flex-wrap items-center gap-3 text-sm">
              <Link
                href={siteConfig.links.download}
                target="_blank"
                rel="noreferrer noopener"
                className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                Download
              </Link>
              <Link
                href={siteConfig.links.testflight}
                target="_blank"
                rel="noreferrer noopener"
                className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                TestFlight
              </Link>
              <Link
                href="/contact"
                className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
              >
                Contact
              </Link>
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
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Product Preview"
            title="A polished workflow across Today, Regulate, and Data"
            description="Switch tabs to preview each product surface and see how the loop stays clear from signal to action."
          />
          <ProductPreviewTabs items={siteConfig.productPreview} />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Live Capture"
            title="Recorded app flow from test runs"
            description="Use these captures as placeholders until final App Store screenshots are exported."
          />
          <div className="grid gap-4 md:grid-cols-2">
            <article className="surface-card overflow-hidden p-3">
              <video
                src="/media/preview-small.mp4"
                className="h-auto w-full rounded-2xl"
                controls
                muted
                playsInline
                loop
                preload="none"
              />
              <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">Compact device run</p>
            </article>
            <article className="surface-card overflow-hidden p-3">
              <video
                src="/media/preview-large.mp4"
                className="h-auto w-full rounded-2xl"
                controls
                muted
                playsInline
                loop
                preload="none"
              />
              <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">Large device run</p>
            </article>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-6">
          <SectionHeading
            eyebrow="Why It Is Different"
            title="Built for transparent, scenario-based guidance"
            description="MindSense is designed for trust and practical daily use, not generic one-size-fits-all advice."
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
            eyebrow="Credibility"
            title="Built for real-world users and pilot partners"
            description="Use these placeholder slots while you finalize testimonials and customer logos."
          />

          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
            {siteConfig.audienceCards.map((item) => (
              <div
                key={item}
                className="rounded-full border border-ink-300 bg-white px-4 py-2 text-center text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-900 dark:text-ink-200"
              >
                {item}
              </div>
            ))}
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            {siteConfig.testimonials.map((quote) => (
              <article key={quote.quote} className="surface-card p-5">
                <p className="text-sm text-ink-700 dark:text-ink-200">“{quote.quote}”</p>
                <p className="mt-3 text-xs font-medium uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">
                  {quote.author} — {quote.role}
                </p>
              </article>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <CtaBand
            title="See a demo tailored to your use case"
            subtitle="For investors, prospective clients, and pilot teams. We will walk through state logic, protocol flow, and rollout options."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-6 md:grid-cols-[1.1fr_0.9fr]">
          <div>
            <SectionHeading
              eyebrow="Waitlist"
              title="Get product updates and pilot openings"
              description="Join the waitlist to receive release updates, pilot invites, and roadmap milestones."
            />
            <p className="mt-4 text-sm text-ink-600 dark:text-ink-300">
              Prefer direct contact? Email{" "}
              <a className="text-accent-700 dark:text-accent-300" href={`mailto:${siteConfig.email}`}>
                {siteConfig.email}
              </a>
              .
            </p>
          </div>
          <LeadForm
            mode="waitlist"
            submitLabel="Join waitlist"
            endpoint={siteConfig.formEndpoints.waitlist || undefined}
          />
        </section>
      </Reveal>
    </div>
  );
}
