import type { Metadata } from "next";
import { siteConfig } from "@/lib/site-config";

const ogImagePath = "/brand/app-icon-1024.png";

export function buildMetadata(title: string, description: string): Metadata {
  const absoluteOgImage = new URL(ogImagePath, siteConfig.siteUrl).toString();

  return {
    title,
    description,
    metadataBase: new URL(siteConfig.siteUrl),
    openGraph: {
      title,
      description,
      type: "website",
      siteName: siteConfig.appName,
      url: siteConfig.siteUrl,
      images: [
        {
          url: absoluteOgImage,
          width: 1024,
          height: 1024,
          alt: `${siteConfig.appName} preview`,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [absoluteOgImage],
    },
  };
}
