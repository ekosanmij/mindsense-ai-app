import Link from "next/link";
import { Reveal } from "@/components/reveal";
import { ScreenshotGallery } from "@/components/screenshot-gallery";
import { SectionHeading } from "@/components/section-heading";
import { buildMetadata } from "@/lib/metadata";
import { productScreenshots } from "@/lib/screenshots";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(siteConfig.metadata.pressTitle, siteConfig.metadata.pressDescription);

const logoAssets = [
  { name: "Logo Icon (Dark SVG)", href: "/press/logos/logo-icon-dark.svg" },
  { name: "Logo Icon (Light SVG)", href: "/press/logos/logo-icon-light.svg" },
  { name: "App Icon PNG", href: "/press/logos/app-icon-1024.png" },
];

const screenshotDownloads = productScreenshots.map((item) => ({
  name: item.title,
  href: item.src.replace("/screens/", "/press/screens/"),
}));

export default function PressPage() {
  return (
    <div className="space-y-14 md:space-y-20">
      <Reveal>
        <section className="section-space">
          <SectionHeading
            eyebrow="Press Kit"
            title="Brand and product assets"
            description="Download logos, screenshots, and boilerplate information for coverage and partner materials."
          />
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space grid gap-4 md:grid-cols-2">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Downloads</h2>
            <ul className="mt-3 space-y-2 text-sm">
              {logoAssets.map((asset) => (
                <li key={asset.href}>
                  <Link
                    href={asset.href}
                    target="_blank"
                    rel="noreferrer"
                    className="text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
                  >
                    {asset.name}
                  </Link>
                </li>
              ))}
            </ul>
          </article>

          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Boilerplate</h2>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              {siteConfig.appName} is a physiology-aware readiness and regulation platform for focused work and
              recovery. It helps users track readiness, load, and consistency, then run guided protocols with clear
              rationale and weekly learning.
            </p>
            <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
              Company: {siteConfig.companyName}
              <br />
              Founder: {`{Founder Name Placeholder}`}
              <br />
              Press contact:{" "}
              <a href={`mailto:${siteConfig.email}`} className="text-accent-700 dark:text-accent-300">
                {siteConfig.email}
              </a>
            </p>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space">
          <article className="surface-card p-5">
            <h2 className="text-xl font-semibold text-ink-900 dark:text-white">Screenshot downloads</h2>
            <ul className="mt-3 grid gap-2 md:grid-cols-2">
              {screenshotDownloads.map((asset) => (
                <li key={asset.href}>
                  <Link
                    href={asset.href}
                    target="_blank"
                    rel="noreferrer"
                    className="text-sm text-accent-700 hover:text-accent-900 dark:text-accent-300 dark:hover:text-accent-100"
                  >
                    {asset.name}
                  </Link>
                </li>
              ))}
            </ul>
          </article>
        </section>
      </Reveal>

      <Reveal>
        <section className="section-space space-y-5">
          <SectionHeading
            eyebrow="Screens"
            title="Product screenshots"
            description="Replace placeholders in /public/screens with final high-resolution captures."
          />
          <ScreenshotGallery items={productScreenshots} columns={2} />
        </section>
      </Reveal>
    </div>
  );
}
