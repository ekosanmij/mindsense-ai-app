import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.howTitle, siteConfig.metadata.howDescription);

export default function HowItWorksPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="How It Works"
            title="Transparent inputs, practical outputs"
            description="This page explains the model logic at a high level for investors, technical buyers, and pilot partners."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Flow" title="Input → Processing → Output" />
          <div className="surface-card grid-bg grid gap-4 p-6 md:grid-cols-3">
            <article className="rounded-2xl border border-ink-200 bg-white/90 p-4 dark:border-ink-700 dark:bg-ink-950/80">
              <h2 className="text-lg font-semibold text-ink-900 dark:text-white">Inputs</h2>
              <ul className="mt-3 space-y-1.5 text-sm text-ink-600 dark:text-ink-300">
                <li>Apple Watch + Apple Health signals</li>
                <li>User check-ins and context notes</li>
                <li>Session adherence and impact reports</li>
              </ul>
            </article>
            <article className="rounded-2xl border border-ink-200 bg-white/90 p-4 dark:border-ink-700 dark:bg-ink-950/80">
              <h2 className="text-lg font-semibold text-ink-900 dark:text-white">Processing</h2>
              <ul className="mt-3 space-y-1.5 text-sm text-ink-600 dark:text-ink-300">
                <li>Signal interpretation + heuristic scoring</li>
                <li>Readiness/load/consistency estimation</li>
                <li>Scenario-aware recommendation selection</li>
              </ul>
            </article>
            <article className="rounded-2xl border border-ink-200 bg-white/90 p-4 dark:border-ink-700 dark:bg-ink-950/80">
              <h2 className="text-lg font-semibold text-ink-900 dark:text-white">Outputs</h2>
              <ul className="mt-3 space-y-1.5 text-sm text-ink-600 dark:text-ink-300">
                <li>Current state + confidence context</li>
                <li>One recommended protocol and rationale</li>
                <li>Weekly experiment learning summary</li>
              </ul>
            </article>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Estimate & Rationale" title="Why we prioritize transparency over black-box advice" />
          <div className="grid gap-4 md:grid-cols-2">
            <article className="surface-card p-5">
              <h3 className="text-lg font-semibold text-ink-900 dark:text-white">Confidence and Coverage</h3>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
                Every recommendation can be framed with confidence and data coverage cues so users understand signal
                quality before acting.
              </p>
            </article>
            <article className="surface-card p-5">
              <h3 className="text-lg font-semibold text-ink-900 dark:text-white">Plain-Language Rationale</h3>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
                Users see why a recommendation appears, reducing ambiguity and improving trust in daily behavior.
              </p>
            </article>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Experiment System" title="7-day experiments that produce weekly learning" />
          <div className="surface-card p-5">
            <ol className="grid gap-4 md:grid-cols-3">
              <li className="rounded-2xl border border-ink-200 bg-ink-50 p-4 text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-200">
                <span className="chip">Step 1</span>
                <p className="mt-2 font-medium">Define experiment</p>
                <p className="mt-1">Choose a protocol and a realistic frequency target for seven days.</p>
              </li>
              <li className="rounded-2xl border border-ink-200 bg-ink-50 p-4 text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-200">
                <span className="chip">Step 2</span>
                <p className="mt-2 font-medium">Track adherence + effect</p>
                <p className="mt-1">Capture completion and perceived impact after each session.</p>
              </li>
              <li className="rounded-2xl border border-ink-200 bg-ink-50 p-4 text-sm text-ink-700 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-200">
                <span className="chip">Step 3</span>
                <p className="mt-2 font-medium">Generate weekly learning</p>
                <p className="mt-1">Review observed patterns and decide what to keep, adjust, or stop.</p>
              </li>
            </ol>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading eyebrow="Safety Boundaries" title="Supportive, clear, and bounded" />
          <div className="surface-card p-5">
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              <li>MindSense AI includes crisis-resource direction where appropriate.</li>
              <li>It is not an emergency service and does not replace licensed clinical care.</li>
              <li>Language is intentionally calm, non-alarmist, and action-oriented.</li>
            </ul>
          </div>
        </section>
      </Reveal>
    </div>
  );
}
