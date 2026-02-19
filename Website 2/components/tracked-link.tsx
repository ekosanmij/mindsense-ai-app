"use client";

import Link from "next/link";
import { ReactNode } from "react";
import type { TrackEventName, TrackPayload } from "@/lib/tracking";
import { trackEvent } from "@/lib/tracking";

type TrackedLinkProps = {
  href: string;
  className?: string;
  children: ReactNode;
  eventName?: TrackEventName;
  eventPayload?: TrackPayload;
  external?: boolean;
  onClick?: () => void;
};

export function TrackedLink({
  href,
  className,
  children,
  eventName,
  eventPayload,
  external,
  onClick,
}: TrackedLinkProps) {
  const isExternal = external ?? /^https?:\/\//.test(href) || href.startsWith("mailto:");

  const handleClick = () => {
    if (eventName) {
      trackEvent(eventName, eventPayload);
    }
    onClick?.();
  };

  if (isExternal) {
    return (
      <a
        href={href}
        target={href.startsWith("mailto:") ? undefined : "_blank"}
        rel={href.startsWith("mailto:") ? undefined : "noreferrer noopener"}
        className={className}
        onClick={handleClick}
      >
        {children}
      </a>
    );
  }

  return (
    <Link href={href} className={className} onClick={handleClick}>
      {children}
    </Link>
  );
}
