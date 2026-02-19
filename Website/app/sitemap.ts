import type { MetadataRoute } from "next";
import { routesForSitemap, siteConfig } from "@/lib/site-config";
import { getUpdateSlugs } from "@/lib/updates";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const staticRoutes: MetadataRoute.Sitemap = routesForSitemap.map((route) => ({
    url: `${siteConfig.siteUrl}${route}`,
    lastModified: new Date(),
    changeFrequency: route === "/" ? "weekly" : "monthly",
    priority: route === "/" ? 1 : 0.7,
  }));

  const updateRoutes = (await getUpdateSlugs()).map((slug) => ({
    url: `${siteConfig.siteUrl}/updates/${slug}`,
    lastModified: new Date(),
    changeFrequency: "monthly" as const,
    priority: 0.6,
  }));

  return [...staticRoutes, ...updateRoutes];
}
