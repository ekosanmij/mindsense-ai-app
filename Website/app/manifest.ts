import type { MetadataRoute } from "next";
import { siteConfig } from "@/lib/site-config";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: siteConfig.appName,
    short_name: siteConfig.appName,
    description: siteConfig.description,
    start_url: "/",
    display: "standalone",
    background_color: "#0d1e29",
    theme_color: "#0b87ac",
    icons: [
      {
        src: "/brand/app-icon-1024.png",
        sizes: "1024x1024",
        type: "image/png",
      },
    ],
  };
}
