import { buildMetadata } from "@/lib/metadata";
import { siteConfig } from "@/lib/site-config";

export const metadata = buildMetadata(
  "Verify your magic link",
  "Continue your MindSense sign-in from your magic-link email.",
);

type SearchParamValue = string | string[] | undefined;
type VerifySearchParams = Record<string, SearchParamValue>;
type VerifyPageProps = {
  searchParams: Promise<VerifySearchParams>;
};

function firstValue(value: SearchParamValue): string | undefined {
  if (Array.isArray(value)) {
    for (const entry of value) {
      const trimmed = entry.trim();
      if (trimmed.length > 0) {
        return trimmed;
      }
    }
    return undefined;
  }

  const trimmed = value?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : undefined;
}

function buildAppLink(searchParams: VerifySearchParams): string {
  const token =
    firstValue(searchParams.token) ??
    firstValue(searchParams.code) ??
    firstValue(searchParams.magic_token);
  const email = firstValue(searchParams.email);
  const intent = firstValue(searchParams.intent);

  const query = new URLSearchParams();
  if (token) {
    query.set("token", token);
  }
  if (email) {
    query.set("email", email);
  }
  if (intent) {
    query.set("intent", intent);
  }

  const encodedQuery = query.toString();
  if (encodedQuery.length === 0) {
    return "mindsense://auth/verify";
  }
  return `mindsense://auth/verify?${encodedQuery}`;
}

export default async function VerifyPage({ searchParams }: VerifyPageProps) {
  const resolvedSearchParams = await searchParams;
  const token =
    firstValue(resolvedSearchParams.token) ??
    firstValue(resolvedSearchParams.code) ??
    firstValue(resolvedSearchParams.magic_token);
  const email = firstValue(resolvedSearchParams.email);
  const appLink = buildAppLink(resolvedSearchParams);
  const hasRequiredFields = Boolean(token && email);

  return (
    <section className="section-space">
      <article className="surface-card mx-auto max-w-2xl space-y-6 p-6 md:p-8">
        <p className="chip">MindSense access</p>
        <div className="space-y-2">
          <h1 className="text-3xl font-semibold tracking-tight text-ink-900 dark:text-white">
            {hasRequiredFields ? "Continue in the app" : "Link details are missing"}
          </h1>
          <p className="text-sm text-ink-600 dark:text-ink-300">
            {hasRequiredFields
              ? `Use this button to complete sign-in for ${email}.`
              : "This verification link is incomplete. Request a new magic link from the app and try again."}
          </p>
        </div>

        {hasRequiredFields ? (
          <div className="space-y-3">
            <a
              href={appLink}
              className="inline-flex items-center justify-center rounded-full bg-accent-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-accent-600"
            >
              Open MindSense
            </a>
            <p className="text-xs text-ink-500 dark:text-ink-400">
              If the app does not open, install it first and then try this link again.
            </p>
          </div>
        ) : (
          <a
            href={siteConfig.links.getApp}
            className="inline-flex items-center justify-center rounded-full bg-accent-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-accent-600"
          >
            Install MindSense
          </a>
        )}
      </article>
    </section>
  );
}
