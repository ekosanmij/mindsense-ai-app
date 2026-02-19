"use client";

import { FormEvent, useMemo, useState } from "react";

type LeadFormMode = "waitlist" | "contact";

type LeadFormProps = {
  mode: LeadFormMode;
  endpoint?: string;
  submitLabel: string;
  className?: string;
};

type Status = "idle" | "loading" | "success" | "error";

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function LeadForm({ mode, endpoint, submitLabel, className }: LeadFormProps) {
  const [status, setStatus] = useState<Status>("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [values, setValues] = useState({
    name: "",
    email: "",
    message: "",
    company: "",
    honeypot: "",
  });

  const isContactMode = mode === "contact";

  const validationError = useMemo(() => {
    if (!values.email || !emailRegex.test(values.email)) return "Enter a valid email address.";
    if (isContactMode && !values.name.trim()) return "Please add your name.";
    if (isContactMode && values.message.trim().length < 10) return "Please add a short message (10+ characters).";
    return "";
  }, [isContactMode, values.email, values.message, values.name]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setErrorMessage("");

    if (values.honeypot.trim()) {
      setStatus("success");
      return;
    }

    if (validationError) {
      setErrorMessage(validationError);
      setStatus("error");
      return;
    }

    setStatus("loading");

    try {
      const payload = {
        type: mode,
        name: values.name.trim(),
        email: values.email.trim(),
        company: values.company.trim(),
        message: values.message.trim(),
        submittedAt: new Date().toISOString(),
      };

      if (endpoint) {
        const response = await fetch(endpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (!response.ok) {
          throw new Error("Unable to submit at the moment.");
        }
      } else {
        // Placeholder until a provider endpoint is connected.
        console.info("Lead form placeholder submission", payload);
      }

      setStatus("success");
      setValues((prev) => ({ ...prev, message: "" }));
    } catch (error) {
      setStatus("error");
      setErrorMessage(error instanceof Error ? error.message : "Submission failed. Please try again.");
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className={`rounded-xl2 border border-ink-200 bg-white p-5 shadow-card dark:border-ink-800 dark:bg-ink-900 ${className ?? ""}`}
      noValidate
    >
      <div className="grid gap-3">
        {isContactMode ? (
          <label className="grid gap-1 text-sm text-ink-700 dark:text-ink-200">
            Name
            <input
              type="text"
              value={values.name}
              onChange={(event) => setValues((prev) => ({ ...prev, name: event.target.value }))}
              className="rounded-xl border border-ink-200 bg-white px-3 py-2 text-ink-900 outline-none transition focus:border-accent-500 focus:ring-2 focus:ring-accent-200 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-100 dark:focus:ring-accent-800"
              placeholder="Your name"
              autoComplete="name"
            />
          </label>
        ) : null}

        <label className="grid gap-1 text-sm text-ink-700 dark:text-ink-200">
          Email
          <input
            type="email"
            value={values.email}
            onChange={(event) => setValues((prev) => ({ ...prev, email: event.target.value }))}
            className="rounded-xl border border-ink-200 bg-white px-3 py-2 text-ink-900 outline-none transition focus:border-accent-500 focus:ring-2 focus:ring-accent-200 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-100 dark:focus:ring-accent-800"
            placeholder="you@company.com"
            autoComplete="email"
            required
          />
        </label>

        <label className="grid gap-1 text-sm text-ink-700 dark:text-ink-200">
          Company (optional)
          <input
            type="text"
            value={values.company}
            onChange={(event) => setValues((prev) => ({ ...prev, company: event.target.value }))}
            className="rounded-xl border border-ink-200 bg-white px-3 py-2 text-ink-900 outline-none transition focus:border-accent-500 focus:ring-2 focus:ring-accent-200 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-100 dark:focus:ring-accent-800"
            placeholder="Company name"
            autoComplete="organization"
          />
        </label>

        {isContactMode ? (
          <label className="grid gap-1 text-sm text-ink-700 dark:text-ink-200">
            Message
            <textarea
              rows={5}
              value={values.message}
              onChange={(event) => setValues((prev) => ({ ...prev, message: event.target.value }))}
              className="rounded-xl border border-ink-200 bg-white px-3 py-2 text-ink-900 outline-none transition focus:border-accent-500 focus:ring-2 focus:ring-accent-200 dark:border-ink-700 dark:bg-ink-950 dark:text-ink-100 dark:focus:ring-accent-800"
              placeholder="Tell us about your use case."
              required
            />
          </label>
        ) : null}

        <label className="hidden" aria-hidden="true">
          Leave blank
          <input
            tabIndex={-1}
            autoComplete="off"
            value={values.honeypot}
            onChange={(event) => setValues((prev) => ({ ...prev, honeypot: event.target.value }))}
          />
        </label>

        <button
          type="submit"
          disabled={status === "loading"}
          className="inline-flex items-center justify-center rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white transition hover:bg-accent-600 disabled:cursor-not-allowed disabled:opacity-70"
        >
          {status === "loading" ? "Submitting..." : submitLabel}
        </button>
      </div>

      {status === "success" ? (
        <p className="mt-3 text-sm text-emerald-700 dark:text-emerald-300">
          Submission received. We will follow up soon.
        </p>
      ) : null}
      {status === "error" && errorMessage ? (
        <p className="mt-3 text-sm text-red-700 dark:text-red-300">{errorMessage}</p>
      ) : null}
    </form>
  );
}
