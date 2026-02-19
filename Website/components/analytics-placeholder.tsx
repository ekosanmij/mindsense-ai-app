import Script from "next/script";
import { siteConfig } from "@/lib/site-config";

export function AnalyticsPlaceholder() {
  if (!siteConfig.analytics.enabled) return null;

  return (
    <>
      <Script id="analytics-provider" strategy="afterInteractive">
        {`
          window.__MS_ANALYTICS_PROVIDER__ = "${siteConfig.analytics.provider}";
          window.__MS_ANALYTICS_KEY__ = "${siteConfig.analytics.key}";
          console.info("Analytics placeholder enabled. Wire your provider here.");
        `}
      </Script>
    </>
  );
}
