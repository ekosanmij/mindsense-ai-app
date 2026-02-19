export type TrackEventName =
  | "cta_get_app_clicked"
  | "cta_join_beta_submitted"
  | "cta_book_pilot_clicked"
  | "cta_investor_deck_submitted"
  | "demo_interaction_started"
  | "protocol_preview_opened";

export type TrackPayload = Record<string, string | number | boolean | null | undefined>;

declare global {
  interface Window {
    dataLayer?: Array<Record<string, unknown>>;
  }
}

export function trackEvent(event: TrackEventName, payload: TrackPayload = {}): void {
  if (typeof window === "undefined") return;

  const entry = {
    event,
    timestamp: new Date().toISOString(),
    ...payload,
  };

  window.dataLayer = window.dataLayer ?? [];
  window.dataLayer.push(entry);

  // Placeholder sink while analytics provider is not connected.
  console.info("[analytics]", entry);
}
