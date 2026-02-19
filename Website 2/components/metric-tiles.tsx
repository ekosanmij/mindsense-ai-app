type MetricTile = {
  label: string;
  value: string;
  detail: string;
};

type MetricTilesProps = {
  items: MetricTile[];
};

export function MetricTiles({ items }: MetricTilesProps) {
  return (
    <div className="grid gap-4 md:grid-cols-3">
      {items.map((item) => (
        <article
          key={item.label}
          className="rounded-xl2 border border-ink-200 bg-white p-5 shadow-card dark:border-ink-800 dark:bg-ink-900"
        >
          <p className="text-xs font-semibold uppercase tracking-[0.15em] text-accent-700 dark:text-accent-300">
            {item.label}
          </p>
          <p className="mt-2 text-2xl font-semibold text-ink-900 dark:text-white">{item.value}</p>
          <p className="mt-2 text-sm text-ink-600 dark:text-ink-300">{item.detail}</p>
        </article>
      ))}
    </div>
  );
}
