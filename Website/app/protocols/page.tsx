import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { TrackedLink } from "@/components/tracked-link";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.protocolsTitle, siteConfig.metadata.protocolsDescription);

const protocolSteps: Record<string, string[]> = {
  "Calm Now": [
    "Orient and slow breathing",
    "Downshift arousal cadence",
    "Capture immediate impact"
  ],
  "Focus Prep": [
    "Reduce cognitive noise",
    "Stabilize breathing and attention",
    "Start focused work block"
  ],
  "Sleep Downshift": [
    "Lower evening activation",
    "Set slower pacing and cues",
    "Log pre-sleep readiness shift"
  ]
};

export default function ProtocolsPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Protocols"
            title="Protocol paths for real nervous-system contexts"
            description="MindSense recommends one protocol at a time based on current state. Each protocol is short, guided, and measurable."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-5 md:grid-cols-3">
          {siteConfig.protocols.map((protocol) => (
            <article key={protocol.name} className="surface-card p-5">
              <h2 className="text-2xl font-semibold text-ink-900 dark:text-white">{protocol.name}</h2>
              <p className="mt-1 text-sm font-medium text-accent-700 dark:text-accent-300">{protocol.duration}</p>

              <div className="mt-4 space-y-3 text-sm text-ink-600 dark:text-ink-300">
                <p><span className="font-semibold text-ink-800 dark:text-ink-100">When to use:</span> {protocol.when}</p>
                <p><span className="font-semibold text-ink-800 dark:text-ink-100">Immediate shift:</span> {protocol.immediate}</p>
                <p><span className="font-semibold text-ink-800 dark:text-ink-100">7-day change:</span> {protocol.week}</p>
              </div>

              <div className="mt-4 rounded-xl border border-ink-200 bg-ink-50 p-3 dark:border-ink-700 dark:bg-ink-950">
                <p className="text-xs uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">Step flow</p>
                <ol className="mt-2 space-y-1.5 text-sm text-ink-700 dark:text-ink-200">
                  {(protocolSteps[protocol.name] ?? []).map((step) => (
                    <li key={step} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{step}</span></li>
                  ))}
                </ol>
              </div>

              <TrackedLink
                href={siteConfig.links.getApp}
                eventName="cta_get_app_clicked"
                eventPayload={{ source: "protocols_page", protocol: protocol.name }}
                className="mt-4 inline-flex rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600"
              >
                Open in app
              </TrackedLink>
            </article>
          ))}
        </section>
      </Reveal>
    </div>
  );
}
