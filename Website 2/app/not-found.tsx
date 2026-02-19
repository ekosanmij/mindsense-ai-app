import Link from "next/link";

export default function NotFound() {
  return (
    <section className="section-space">
      <div className="surface-card mx-auto max-w-xl p-8 text-center">
        <p className="text-sm uppercase tracking-[0.14em] text-ink-500 dark:text-ink-400">404</p>
        <h1 className="mt-2 text-3xl font-semibold text-ink-900 dark:text-white">Page not found</h1>
        <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">
          The page you requested could not be found.
        </p>
        <Link
          href="/"
          className="mt-5 inline-flex rounded-full bg-accent-500 px-4 py-2 text-sm font-semibold text-white hover:bg-accent-600"
        >
          Return home
        </Link>
      </div>
    </section>
  );
}
