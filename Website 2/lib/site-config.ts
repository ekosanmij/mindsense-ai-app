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
    getApp: string;
    joinBeta: string;
    bookPilot: string;
    requestDeck: string;
    privacy: string;
    support: string;
  };
  formEndpoints: {
    waitlist: string;
    contact: string;
    investor: string;
  };
  socials: SocialLink[];
  outcomes: Array<{ title: string; description: string }>;
  productPreview: ProductPreviewItem[];
  differentiators: string[];
  proofPoints: string[];
  productPillars: Array<{ title: string; summary: string }>;
  productFeatures: string[];
  faq: FAQItem[];
  protocols: Array<{
    name: string;
    duration: string;
    when: string;
    immediate: string;
    week: string;
  }>;
  teams: {
    forWho: string[];
    valueProps: string[];
    pilot: string[];
    tiers: string[];
    weeklyDeliverables: string[];
    successMetrics: string[];
    operators: string[];
  };
  trust: {
    privacy: string[];
    security: string[];
    safety: string[];
    dataRights: string[];
  };
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
  { href: "/protocols", label: "Protocols" },
  { href: "/how-it-works", label: "How it works" },
  { href: "/trust", label: "Trust" },
  { href: "/teams", label: "Teams" },
  { href: "/updates", label: "Updates" },
  { href: "/press", label: "Press" },
];

export const footerNavLinks: NavLink[] = [
  { href: "/", label: "Home" },
  { href: "/product", label: "Product" },
  { href: "/protocols", label: "Protocols" },
  { href: "/how-it-works", label: "How it works" },
  { href: "/trust", label: "Trust Center" },
  { href: "/teams", label: "Teams" },
  { href: "/updates", label: "Updates" },
  { href: "/contact", label: "Contact" },
  { href: "/press", label: "Press Kit" },
];

export const routesForSitemap = [
  "/",
  "/product",
  "/protocols",
  "/how-it-works",
  "/trust",
  "/trust/privacy",
  "/trust/security",
  "/trust/safety",
  "/trust/data-rights",
  "/teams",
  "/updates",
  "/contact",
  "/press",
];
