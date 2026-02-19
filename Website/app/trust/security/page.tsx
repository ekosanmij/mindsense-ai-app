import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata("Security | MindSense AI", "Security posture and operational controls for MindSense AI.");

const controls = [
  "Local-first architecture where supported by platform capabilities",
  "Transport-level security for networked operations",
  "Access control practices based on least privilege",
  "Operational audit posture for support and incident response",
];

export default function TrustSecurityPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Trust • Security"
            title="Security posture"
            description="MindSense security controls are designed to protect user data and minimize unnecessary access pathways."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <div className="surface-card p-5">
            <ul className="space-y-2 text-sm text-ink-600 dark:text-ink-300">
              {controls.map((item) => (
                <li key={item} className="flex gap-2"><span className="mt-1 text-accent-500">•</span><span>{item}</span></li>
              ))}
            </ul>
          </div>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <div className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Security contact</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              To report a potential security issue, contact <a className="text-accent-700 dark:text-accent-300" href={siteConfig.links.support}>{siteConfig.email}</a>.
            </p>
          </div>
        </section>
      </Reveal>
    </div>
  );
}
