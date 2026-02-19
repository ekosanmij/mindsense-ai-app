type FAQItem = {
  question: string;
  answer: string;
};

type FAQAccordionProps = {
  items: FAQItem[];
};

export function FAQAccordion({ items }: FAQAccordionProps) {
  return (
    <div className="space-y-3">
      {items.map((item) => (
        <details
          key={item.question}
          className="group rounded-2xl border border-ink-200 bg-white p-5 shadow-card transition open:border-accent-300 dark:border-ink-800 dark:bg-ink-900 dark:open:border-accent-700"
        >
          <summary className="cursor-pointer list-none text-base font-semibold text-ink-900 dark:text-white">
            <span>{item.question}</span>
            <span className="ml-2 text-accent-700 transition group-open:rotate-45 dark:text-accent-300">+</span>
          </summary>
          <p className="mt-3 text-sm text-ink-600 dark:text-ink-300">{item.answer}</p>
        </details>
      ))}
    </div>
  );
}
