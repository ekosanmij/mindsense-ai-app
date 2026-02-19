"use client";

import { useMemo, useRef, useState } from "react";
import { TrackedLink } from "@/components/tracked-link";
import { trackEvent } from "@/lib/tracking";
import { siteConfig } from "@/lib/site-config";

type ContextKey = "highStress" | "balanced" | "recovery";

type StateModel = {
  load: number;
  readiness: number;
  consistency: number;
};

const presets: Record<ContextKey, StateModel> = {
  highStress: { load: 82, readiness: 31, consistency: 42 },
  balanced: { load: 44, readiness: 69, consistency: 73 },
  recovery: { load: 58, readiness: 56, consistency: 64 },
};

const contextLabels: Record<ContextKey, string> = {
  highStress: "High stress day",
  balanced: "Balanced day",
  recovery: "Recovery week",
};

type Recommendation = {
  protocol: "Calm Now" | "Focus Prep" | "Sleep Downshift";
  reason: string;
  confidenceLabel: "High" | "Medium" | "Low";
  coverageLabel: "Strong" | "Moderate" | "Limited";
  confidenceScore: number;
  coverageScore: number;
};

function calculateRecommendation(state: StateModel): Recommendation {
  let protocol: Recommendation["protocol"] = "Focus Prep";
  let reason = "State is stable enough to prepare for focused output.";

  if (state.readiness <= 40 || state.load >= 70) {
    protocol = "Calm Now";
    reason = "Load is elevated relative to readiness. Calm first to prevent a sharper crash.";
  } else if (state.consistency <= 48 || (state.readiness < 58 && state.load > 55)) {
    protocol = "Sleep Downshift";
    reason = "Recovery signals are uneven. Downshift to protect tomorrow's readiness.";
  }

  const confidenceScore = Math.max(
    18,
    Math.min(95, Math.round(0.35 * state.consistency + 0.3 * state.readiness + 0.35 * (100 - state.load))),
  );
  const coverageScore = Math.max(15, Math.min(95, Math.round(0.7 * state.consistency + 0.3 * state.readiness)));

  const confidenceLabel: Recommendation["confidenceLabel"] =
    confidenceScore >= 72 ? "High" : confidenceScore >= 48 ? "Medium" : "Low";
  const coverageLabel: Recommendation["coverageLabel"] =
    coverageScore >= 70 ? "Strong" : coverageScore >= 45 ? "Moderate" : "Limited";

  return {
    protocol,
    reason,
    confidenceLabel,
    coverageLabel,
    confidenceScore,
    coverageScore,
  };
}

export function InteractiveLoopDemo() {
  const [context, setContext] = useState<ContextKey>("balanced");
  const [state, setState] = useState<StateModel>(presets.balanced);
  const interactionStarted = useRef(false);

  const recommendation = useMemo(() => calculateRecommendation(state), [state]);

  const markInteractionStart = (source: string) => {
    if (interactionStarted.current) return;
    interactionStarted.current = true;
    trackEvent("demo_interaction_started", { source });
  };

  const handleContextChange = (next: ContextKey) => {
    markInteractionStart("context_select");
    setContext(next);
    setState(presets[next]);
  };

  const updateSlider = (key: keyof StateModel, value: number) => {
    markInteractionStart(`slider_${key}`);
    setState((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <section className="surface-card overflow-hidden p-5 md:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-accent-700 dark:text-accent-300">
            Try MindSense in 30 seconds
          </p>
          <h2 className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">Signal → action simulation</h2>
          <p className="mt-2 max-w-2xl text-sm text-ink-600 dark:text-ink-300">
            Select a context, adjust load/readiness/consistency, and get one protocol recommendation with rationale.
          </p>
        </div>
      </div>

      <div className="mt-5 grid gap-4 md:grid-cols-[1fr_1fr]">
        <article className="rounded-2xl border border-ink-200 bg-ink-50 p-4 dark:border-ink-700 dark:bg-ink-950">
          <p className="text-xs font-semibold uppercase tracking-[0.15em] text-ink-500 dark:text-ink-400">Context</p>
          <div className="mt-3 grid gap-2 sm:grid-cols-3">
            {(Object.keys(contextLabels) as ContextKey[]).map((key) => (
              <button
                key={key}
                type="button"
                onClick={() => handleContextChange(key)}
                className={`rounded-xl px-3 py-2 text-sm font-medium transition ${
                  context === key
                    ? "bg-accent-500 text-white"
                    : "bg-white text-ink-700 hover:bg-ink-100 dark:bg-ink-900 dark:text-ink-200 dark:hover:bg-ink-800"
                }`}
              >
                {contextLabels[key]}
              </button>
            ))}
          </div>

          <div className="mt-5 space-y-4">
            {["load", "readiness", "consistency"].map((field) => {
              const key = field as keyof StateModel;
              return (
                <label key={field} className="grid gap-2 text-sm text-ink-700 dark:text-ink-200">
                  <div className="flex items-center justify-between">
                    <span className="capitalize">{field}</span>
                    <span className="font-semibold">{state[key]}</span>
                  </div>
                  <input
                    type="range"
                    min={0}
                    max={100}
                    value={state[key]}
                    onChange={(event) => updateSlider(key, Number(event.target.value))}
                    className="w-full accent-accent-500"
                  />
                </label>
              );
            })}
          </div>
        </article>

        <article className="rounded-2xl border border-ink-200 bg-white p-4 dark:border-ink-700 dark:bg-ink-900">
          <p className="text-xs font-semibold uppercase tracking-[0.15em] text-ink-500 dark:text-ink-400">
            Recommended next step
          </p>
          <h3 className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">{recommendation.protocol}</h3>
          <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{recommendation.reason}</p>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <div className="rounded-xl border border-ink-200 bg-ink-50 p-3 dark:border-ink-700 dark:bg-ink-950">
              <p className="text-xs uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">Confidence</p>
              <p className="mt-1 text-lg font-semibold text-ink-900 dark:text-white">
                {recommendation.confidenceLabel} ({recommendation.confidenceScore}%)
              </p>
            </div>
            <div className="rounded-xl border border-ink-200 bg-ink-50 p-3 dark:border-ink-700 dark:bg-ink-950">
              <p className="text-xs uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">Coverage</p>
              <p className="mt-1 text-lg font-semibold text-ink-900 dark:text-white">
                {recommendation.coverageLabel} ({recommendation.coverageScore}%)
              </p>
            </div>
          </div>

          <div className="mt-5 flex flex-wrap gap-2">
            <TrackedLink
              href={siteConfig.links.getApp}
              eventName="cta_get_app_clicked"
              eventPayload={{ source: "interactive_demo", protocol: recommendation.protocol }}
              className="inline-flex items-center justify-center rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600"
            >
              Run this in the app
            </TrackedLink>
            <TrackedLink
              href="/protocols"
              eventName="protocol_preview_opened"
              eventPayload={{ source: "interactive_demo", protocol: recommendation.protocol }}
              className="inline-flex items-center justify-center rounded-full border border-ink-300 px-4 py-2 text-sm font-semibold text-ink-900 transition hover:border-accent-400 hover:text-accent-700 dark:border-ink-700 dark:text-ink-100 dark:hover:border-accent-500 dark:hover:text-accent-300"
            >
              View protocol details
            </TrackedLink>
          </div>
        </article>
      </div>
    </section>
  );
}
