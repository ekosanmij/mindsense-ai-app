import siteData from "@/content/site.json";

export type NavLink = {
  href: string;
  label: string;
};

type ProductPreviewItem = {
  id: string;
  title: string;
  image: string;
  bullets: string[];
};

type FAQItem = {
  question: string;
  answer: string;
};

type SocialLink = {
  label: string;
  href: string;
};

export type SiteConfig = {
  appName: string;
  companyName: string;
  siteUrl: string;
  email: string;
  tagline: string;
  description: string;
  hero: {
    headline: string;
    subheadline: string;
    trustLine: string;
  };
  links: {
    bookDemo: string;
    joinWaitlist: string;
    download: string;
    testflight: string;
    privacy: string;
  };
  formEndpoints: {
    waitlist: string;
    contact: string;
  };
  socials: SocialLink[];
  outcomes: Array<{ title: string; description: string }>;
  productPreview: ProductPreviewItem[];
  differentiators: string[];
  audienceCards: string[];
  testimonials: Array<{ quote: string; author: string; role: string }>;
  productPillars: Array<{ title: string; summary: string }>;
  productFeatures: string[];
  faq: FAQItem[];
  teams: {
    forWho: string[];
    valueProps: string[];
    pilot: string[];
  };
  privacySummary: string[];
  roadmap: {
    now: string[];
    next: string[];
    later: string[];
  };
  pilotPackage: string[];
  metadata: Record<string, string>;
  analytics: {
    enabled: boolean;
    provider: "posthog" | "ga4" | string;
    key: string;
  };
};

export const siteConfig = siteData as SiteConfig;

export const topNavLinks: NavLink[] = [
  { href: "/product", label: "Product" },
  { href: "/how-it-works", label: "How It Works" },
  { href: "/for-teams", label: "For Teams" },
  { href: "/updates", label: "Updates" },
  { href: "/press", label: "Press" },
  { href: "/contact", label: "Contact" },
];

export const footerNavLinks: NavLink[] = [
  { href: "/", label: "Home" },
  { href: "/product", label: "Product" },
  { href: "/how-it-works", label: "How It Works" },
  { href: "/for-teams", label: "For Teams" },
  { href: "/privacy", label: "Privacy" },
  { href: "/updates", label: "Updates" },
  { href: "/contact", label: "Contact" },
  { href: "/press", label: "Press Kit" },
];

export const routesForSitemap = [
  "/",
  "/product",
  "/how-it-works",
  "/for-teams",
  "/privacy",
  "/updates",
  "/contact",
  "/press",
];
