import Link from "next/link";
import { LeadForm } from "@/components/lead-form";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.contactTitle, siteConfig.metadata.contactDescription);

export default function ContactPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Contact"
            title="Book a demo or join the waitlist"
            description="Use this form for pilots, partnerships, investor requests, and early-access signups."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-8 md:grid-cols-[1fr_1fr]">
          <div className="space-y-4">
            <article className="surface-card p-5">
              <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Book a demo</h2>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
                Use the Calendly placeholder link below. Replace this URL in /content/site.json.
              </p>
              <Link
                href={siteConfig.links.bookDemo}
                target="_blank"
                rel="noreferrer noopener"
                className="mt-3 inline-flex rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600"
              >
                Open scheduling link
              </Link>
            </article>

            <article className="surface-card p-5">
              <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Direct email</h2>
              <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">
                For support or press inquiries, email{" "}
                <a href={`mailto:${siteConfig.email}`} className="text-accent-700 dark:text-accent-300">
                  {siteConfig.email}
                </a>
                .
              </p>
            </article>
          </div>

          <LeadForm mode="contact" submitLabel="Send message" />
        </section>
      </Reveal>
    </div>
  );
}
