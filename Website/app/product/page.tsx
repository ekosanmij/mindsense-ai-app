import Image from "next/image";
import { FAQAccordion } from "@/components/faq-accordion";
import { Reveal } from "@/components/reveal";
import { ScreenshotGallery } from "@/components/screenshot-gallery";
import { SectionHeading } from "@/components/section-heading";
import { TrackedLink } from "@/components/tracked-link";
import { buildMetadata } from "@/lib/metadata";
import { productScreenshots } from "@/lib/screenshots";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.productTitle, siteConfig.metadata.productDescription);

const loopOutcomes = [
  "Protect recovery windows before they collapse.",
  "Stabilize focused output under variable stress.",
  "Reduce high-load crash cycles with consistent protocol usage.",
];

const todayPoints = [
  "Readiness/load/consistency command view",
  "One recommendation + explicit rationale",
  "Confidence and coverage framing",
  "Context capture for better next-cycle estimates",
];

const regulatePoints = [
  "Protocol selection by scenario",
  "Timer and cue-based guided flow",
  "Post-session impact capture",
  "Low-friction completion and return-to-task UX",
];

const dataPoints = [
  "Readiness vs load trend visibility",
  "7-day experiments and adherence context",
  "History and weekly summary",
  "Explainable learning over time",
];

export default function ProductPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Product"
            title="A real state-to-action product loop"
            description="MindSense AI combines signal interpretation, protocol execution, and learning feedback into one coherent daily flow."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Loop" title="What changes when the loop is used consistently" />
          <div className="grid gap-4 md:grid-cols-3">
            {loopOutcomes.map((outcome) => (
              <article key={outcome} className="surface-card p-5">
                <p className="text-sm text-ink-700 dark:text-ink-200">{outcome}</p>
              </article>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Today" title="State snapshot and one next best step" />
          <div className="surface-card grid gap-5 p-5 md:grid-cols-[1.1fr_1fr]">
            <Image
              src="/screens/today-overview.svg"
              alt="Today screen"
              width={1200}
              height={2600}
              className="h-auto w-full rounded-2xl border border-ink-200 dark:border-ink-700"
            />
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {todayPoints.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Regulate" title="Guided protocol execution" />
          <div className="surface-card grid gap-5 p-5 md:grid-cols-[1.1fr_1fr]">
            <Image
              src="/screens/regulate-flow.svg"
              alt="Regulate screen"
              width={1200}
              height={2600}
              className="h-auto w-full rounded-2xl border border-ink-200 dark:border-ink-700"
            />
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {regulatePoints.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Data" title="Trend and experiment visibility" />
          <div className="surface-card grid gap-5 p-5 md:grid-cols-[1.1fr_1fr]">
            <Image
              src="/screens/data-trends.svg"
              alt="Data trends screen"
              width={1200}
              height={2600}
              className="h-auto w-full rounded-2xl border border-ink-200 dark:border-ink-700"
            />
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {dataPoints.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Trust" title="Built for explainable guidance" />
          <div className="grid gap-4 md:grid-cols-3">
            <article className="surface-card p-5">
              <h3 className="text-lg font-semibold text-ink-900 dark:text-white">Safety boundaries</h3>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">Clear non-emergency guidance and escalation pathways.</p>
            </article>
            <article className="surface-card p-5">
              <h3 className="text-lg font-semibold text-ink-900 dark:text-white">Privacy posture</h3>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">Practical data controls with export and deletion rights.</p>
            </article>
            <article className="surface-card p-5">
              <h3 className="text-lg font-semibold text-ink-900 dark:text-white">Recommendation transparency</h3>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">Confidence and coverage are visible to support trust.</p>
            </article>
          </div>
          <TrackedLink href="/trust" className="inline-flex text-sm font-semibold text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100">
            Visit Trust Center →
          </TrackedLink>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Screenshots" title="Interface gallery" />
          <ScreenshotGallery items={productScreenshots} />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="FAQ" title="What evaluators ask most" />
          <FAQAccordion items={siteConfig.faq} />
        </section>
      </Reveal>
    </div>
  );
}
