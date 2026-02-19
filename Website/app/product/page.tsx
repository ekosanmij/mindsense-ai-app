import { FAQAccordion } from "@/components/faq-accordion";
import { Reveal } from "@/components/reveal";
import { ScreenshotGallery } from "@/components/screenshot-gallery";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { productScreenshots } from "@/lib/screenshots";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.productTitle, siteConfig.metadata.productDescription);

const workflowSteps = [
  {
    title: "1. Sense",
    detail: "Readiness, load, and consistency are summarized from recent signals and check-ins.",
  },
  {
    title: "2. Decide",
    detail: "Estimate and rationale provide a transparent next-step recommendation.",
  },
  {
    title: "3. Do",
    detail: "Guided regulation sessions are optimized for fast starts and low friction.",
  },
  {
    title: "4. Learn",
    detail: "Weekly learning highlights what is helping your recovery and focus patterns.",
  },
];

export default function ProductPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Product"
            title="A coherent product loop, built to feel real and usable"
            description="MindSense AI gives users and teams one daily path: understand state, run a protocol, and learn what works."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Pillars" title="Three surfaces, one consistent workflow" />
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
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="UI Walkthrough" title="From signals to action in four steps" />
          <div className="grid gap-4 md:grid-cols-2">
            {workflowSteps.map((step) => (
              <article key={step.title} className="surface-card p-5">
                <h3 className="text-lg font-semibold text-ink-900 dark:text-white">{step.title}</h3>
                <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{step.detail}</p>
              </article>
            ))}
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Feature Set" title="Scannable capabilities" />
          <div className="surface-card p-5">
            <ul className="grid gap-3 md:grid-cols-2">
              {siteConfig.productFeatures.map((feature) => (
                <li
                  key={feature}
                  className="rounded-xl border border-ink-200 bg-ink-50 px-3 py-2 text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-200"
                >
                  {feature}
                </li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading
            eyebrow="Screenshots"
            title="Product screens"
            description="Replace placeholders in /public/screens with high-resolution app captures."
          />
          <ScreenshotGallery items={productScreenshots} />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="FAQ" title="Common questions" />
          <FAQAccordion items={siteConfig.faq} />
        </section>
      </Reveal>
    </div>
  );
}
