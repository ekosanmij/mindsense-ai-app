import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AnalyticsPlaceholder } from "@/components/analytics-placeholder";
import { MobileCtaBar } from "@/components/mobile-cta-bar";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-inter",
});

export const metadata: Metadata = buildMetadata(
  siteConfig.metadata.defaultTitle,
  siteConfig.metadata.defaultDescription,
);

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f4f8fb" },
    { media: "(prefers-color-scheme: dark)", color: "#0d1e29" },
  ],
};

const themeBootstrapScript = `
  (function () {
    try {
      var saved = localStorage.getItem("theme");
      var systemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      var theme = saved === "light" || saved === "dark" ? saved : (systemDark ? "dark" : "light");
      document.documentElement.classList.toggle("dark", theme === "dark");
      document.documentElement.dataset.theme = theme;
    } catch (e) {}
  })();
`;

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeBootstrapScript }} />
      </head>
      <body className={`${inter.variable} min-h-screen font-sans`}>
        <div className="relative">
          <SiteHeader />
          <main className="mx-auto w-full max-w-6xl px-4 pb-24 pt-8 md:px-6 md:pb-8">{children}</main>
          <SiteFooter />
          <MobileCtaBar />
        </div>
        <AnalyticsPlaceholder />
      </body>
    </html>
  );
}
