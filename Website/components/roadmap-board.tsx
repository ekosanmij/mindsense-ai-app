type RoadmapProps = {
  now: string[];
  next: string[];
  later: string[];
};

export function RoadmapBoard({ now, next, later }: RoadmapProps) {
  const columns = [
    { title: "Now", items: now },
    { title: "Next", items: next },
    { title: "Later", items: later },
  ];

  return (
    <div className="grid gap-4 md:grid-cols-3">
      {columns.map((column) => (
        <article
          key={column.title}
          className="rounded-xl2 border border-ink-200 bg-white p-5 shadow-card dark:border-ink-800 dark:bg-ink-900"
        >
          <h3 className="text-lg font-semibold text-ink-900 dark:text-white">{column.title}</h3>
          <ul className="mt-3 space-y-2 text-sm text-ink-600 dark:text-ink-300">
            {column.items.map((item) => (
              <li key={item} className="flex gap-2">
                <span className="mt-1 text-accent-500">•</span>
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </article>
      ))}
    </div>
  );
}
