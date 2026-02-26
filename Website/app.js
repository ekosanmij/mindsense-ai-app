const prefersReducedMotion =
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const navToggle = document.querySelector(".nav-toggle");
const nav = document.querySelector(".site-nav");
const navLinks = Array.from(document.querySelectorAll('.site-nav a[href^="#"]'));
const header = document.querySelector(".site-header");
const scrollProgressBar = document.getElementById("scroll-progress-bar");

const closeNav = () => {
  if (!nav || !navToggle) {
    return;
  }
  nav.classList.remove("is-open");
  navToggle.setAttribute("aria-expanded", "false");
};

if (navToggle && nav) {
  navToggle.addEventListener("click", () => {
    const isOpen = nav.classList.toggle("is-open");
    navToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
  });

  navLinks.forEach((link) => {
    link.addEventListener("click", closeNav);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeNav();
    }
  });

  document.addEventListener("click", (event) => {
    if (!header) {
      return;
    }
    if (!header.contains(event.target)) {
      closeNav();
    }
  });
}

const updateScrollProgress = () => {
  if (!scrollProgressBar) {
    return;
  }
  const scrollTop = window.scrollY || window.pageYOffset;
  const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
  const ratio = scrollHeight <= 0 ? 0 : Math.max(0, Math.min(1, scrollTop / scrollHeight));
  scrollProgressBar.style.width = `${ratio * 100}%`;
};

window.addEventListener("scroll", updateScrollProgress, { passive: true });
window.addEventListener("resize", updateScrollProgress);
updateScrollProgress();

const sectionLinkMap = new Map();
navLinks.forEach((link) => {
  const hash = link.getAttribute("href");
  if (!hash || !hash.startsWith("#")) {
    return;
  }
  sectionLinkMap.set(hash.slice(1), link);
});

if ("IntersectionObserver" in window && sectionLinkMap.size > 0) {
  const sectionObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const id = entry.target.getAttribute("id");
        if (!id || !sectionLinkMap.has(id) || !entry.isIntersecting) {
          return;
        }
        sectionLinkMap.forEach((node) => node.removeAttribute("aria-current"));
        sectionLinkMap.get(id)?.setAttribute("aria-current", "page");
      });
    },
    {
      rootMargin: "-30% 0px -52% 0px",
      threshold: 0.02
    }
  );

  sectionLinkMap.forEach((_, id) => {
    const section = document.getElementById(id);
    if (section) {
      sectionObserver.observe(section);
    }
  });
}

const metricNodes = Array.from(document.querySelectorAll(".metric[data-count]"));

const animateCount = (node) => {
  const target = Number(node.dataset.count || 0);
  if (!Number.isFinite(target)) {
    return;
  }

  if (prefersReducedMotion) {
    node.textContent = target.toLocaleString();
    return;
  }

  const durationMs = 1150;
  const start = performance.now();

  const tick = (now) => {
    const progress = Math.min((now - start) / durationMs, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    const value = Math.round(target * eased);
    node.textContent = value.toLocaleString();

    if (progress < 1) {
      window.requestAnimationFrame(tick);
    }
  };

  window.requestAnimationFrame(tick);
};

if ("IntersectionObserver" in window && metricNodes.length > 0) {
  const metricObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return;
        }
        animateCount(entry.target);
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.34 }
  );

  metricNodes.forEach((node) => metricObserver.observe(node));
} else {
  metricNodes.forEach((node) => animateCount(node));
}

const loopData = [
  {
    kicker: "Step 1",
    title: "Today: command deck and one primary path",
    copy: "Today surfaces Load, Readiness, and Consistency first, then keeps one dominant action path visible.",
    points: [
      "Primary CTA stays anchored to Start, Continue, or Save check-in depending on state.",
      "Confidence, signal diagnostics, and model details are available without replacing the core action narrative.",
      "Timeline and episode attribution can be reviewed or labeled when needed."
    ]
  },
  {
    kicker: "Step 2",
    title: "Regulate: Select → Run with guided flow",
    copy: "Regulate ranks protocols and moves users through a timed execution flow designed to minimize distraction.",
    points: [
      "Preset catalog: Calm now, Focus prep, Sleep downshift.",
      "Sessions move from in-progress to awaiting check-in as timer milestones complete.",
      "Post-session paywall can appear after first completed outcome submission."
    ]
  },
  {
    kicker: "Step 3",
    title: "Record impact to close today’s loop",
    copy: "Outcome capture records helpfulness and directional impact, then applies deterministic model deltas.",
    points: [
      "Helped/mixed/did-not-help outcomes map to session impact direction and intensity.",
      "Event history and session history update immediately on save.",
      "Confidence and trend narratives are influenced by adherence and repeated loop completion."
    ]
  },
  {
    kicker: "Step 4",
    title: "Data: Trends, Experiments, and History",
    copy: "Data consolidates pattern interpretation, experiment lifecycle tracking, and historical summaries.",
    points: [
      "Trends supports 7D/14D/30D with overlays and optional comparison mode.",
      "Experiments track planned, active, and completed states with adherence.",
      "History summarizes wins, risks, and what-is-working outputs."
    ]
  }
];

const loopStepNodes = Array.from(document.querySelectorAll(".loop-step"));
const loopKicker = document.getElementById("loop-kicker");
const loopTitle = document.getElementById("loop-title");
const loopCopy = document.getElementById("loop-copy");
const loopPoints = document.getElementById("loop-points");
const loopNextButton = document.getElementById("loop-next");

let loopIndex = 0;
let loopIntervalId = null;

const renderLoop = (nextIndex) => {
  if (!loopKicker || !loopTitle || !loopCopy || !loopPoints || loopStepNodes.length === 0) {
    return;
  }

  loopIndex = ((nextIndex % loopData.length) + loopData.length) % loopData.length;
  const payload = loopData[loopIndex];

  loopKicker.textContent = payload.kicker;
  loopTitle.textContent = payload.title;
  loopCopy.textContent = payload.copy;
  loopPoints.innerHTML = payload.points.map((point) => `<li>${point}</li>`).join("");

  loopStepNodes.forEach((node, idx) => {
    const active = idx === loopIndex;
    node.classList.toggle("is-active", active);
    node.setAttribute("tabindex", active ? "0" : "-1");
    node.setAttribute("aria-pressed", active ? "true" : "false");
  });
};

if (loopStepNodes.length > 0) {
  renderLoop(0);

  loopStepNodes.forEach((node, index) => {
    node.addEventListener("click", () => renderLoop(index));

    node.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }

      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        renderLoop(index);
        return;
      }

      let target = index;
      if (event.key === "ArrowRight") {
        target = (index + 1) % loopStepNodes.length;
      } else if (event.key === "ArrowLeft") {
        target = (index - 1 + loopStepNodes.length) % loopStepNodes.length;
      } else if (event.key === "Home") {
        target = 0;
      } else if (event.key === "End") {
        target = loopStepNodes.length - 1;
      }

      renderLoop(target);
      loopStepNodes[target]?.focus();
    });
  });

  loopNextButton?.addEventListener("click", () => renderLoop(loopIndex + 1));

  if (!prefersReducedMotion && "IntersectionObserver" in window) {
    const root = document.getElementById("loop-steps");
    if (root) {
      const loopObserver = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) {
              if (loopIntervalId) {
                window.clearInterval(loopIntervalId);
                loopIntervalId = null;
              }
              return;
            }

            if (!loopIntervalId) {
              loopIntervalId = window.setInterval(() => renderLoop(loopIndex + 1), 5600);
            }
          });
        },
        { threshold: 0.56 }
      );

      loopObserver.observe(root);
    }
  }
}

const tourData = {
  intro: {
    kicker: "Entry",
    image: "./assets/screenshots/optimized/intro-660.jpg",
    srcset: "./assets/screenshots/optimized/intro-660.jpg 660w, ./assets/screenshots/optimized/intro-990.jpg 990w",
    alt: "MindSense intro screen",
    title: "Intro trust framing and Apple sign-in start",
    description: "Introduces value framing and starts the single implemented auth path: Continue with Apple.",
    facts: [
      ["Primary CTA", "Continue with Apple"],
      ["Position in flow", "Launch → Intro → Auth"],
      ["As-built note", "No email-link auth flow is implemented"]
    ],
    bullets: [
      "Highlights state snapshot, one action, and rationale framing.",
      "Keeps setup promise explicit with low-friction copy.",
      "Routes into onboarding or ready state based on persisted session and progress."
    ],
    ctaLabel: "See onboarding activation"
  },
  onboarding: {
    kicker: "Activation",
    image: "./assets/screenshots/optimized/onboarding-660.jpg",
    srcset: "./assets/screenshots/optimized/onboarding-660.jpg 660w, ./assets/screenshots/optimized/onboarding-990.jpg 990w",
    alt: "MindSense onboarding screen",
    title: "Onboarding with required activation steps",
    description: "Activation is sequentially gated for baseline and first check-in before entering the core tabs.",
    facts: [
      ["Required steps", "Start Baseline, First Check-in"],
      ["Progress model", "Step rail + sequential gating"],
      ["Escalation behavior", "High load check-in shows guidance"]
    ],
    bullets: [
      "Connect Health and notifications are shown but not required for activation completion.",
      "On completion, app state transitions to ready and main shell opens.",
      "Supports reduced-motion and accessibility scaling behavior in UI tests."
    ],
    ctaLabel: "Inspect Today command deck"
  },
  today: {
    kicker: "Today",
    image: "./assets/screenshots/optimized/today-660.jpg",
    srcset: "./assets/screenshots/optimized/today-660.jpg 660w, ./assets/screenshots/optimized/today-990.jpg 990w",
    alt: "MindSense Today screen",
    title: "State command deck + one next action",
    description: "Today combines metrics, recommendation, diagnostics, and context capture while preserving one dominant next action path.",
    facts: [
      ["Primary metrics", "Load, Readiness, Consistency"],
      ["Action states", "Start, Continue, or Save check-in"],
      ["Trust framing", "Confidence, coverage, and signal-source details"]
    ],
    bullets: [
      "Low coverage mode shifts behavior toward check-in-first decisions.",
      "Sticky bottom action appears while sessions are active.",
      "Episode attribution and context capture can be edited from Today and Data history."
    ],
    ctaLabel: "View Regulate selection"
  },
  "regulate-select": {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_select-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_select-660.jpg 660w, ./assets/screenshots/optimized/regulate_select-990.jpg 990w",
    alt: "MindSense Regulate selection screen",
    title: "Preset selection and guided structure",
    description: "Regulate presents ranked protocols and an explicit step model before session execution.",
    facts: [
      ["Step model", "Select → Run → Record"],
      ["Preset catalog", "Calm now, Focus prep, Sleep downshift"],
      ["Ranking input", "Scenario, metrics, and outcome history"]
    ],
    bullets: [
      "Preset metadata includes duration and why-now framing.",
      "Predicted fit explanation is available in-context.",
      "Supports launch from Today recommendation and episode-specific context."
    ],
    ctaLabel: "Open run timer phase"
  },
  "regulate-run": {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_run-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_run-660.jpg 660w, ./assets/screenshots/optimized/regulate_run-990.jpg 990w",
    alt: "MindSense Regulate run timer screen",
    title: "Run timer and impact submission",
    description: "Session state progresses to awaiting check-in and applies deterministic outcome deltas when impact is saved.",
    facts: [
      ["Timer behavior", "1-second tick updates"],
      ["Impact capture", "Helped / mixed / did not help + optional context"],
      ["Post session", "May present post-activation paywall sheet"]
    ],
    bullets: [
      "Outcome saves update metrics, history, and saved insights.",
      "Flow supports haptic pacing and optional audio guidance toggles.",
      "Paywall is presentation-level in v1.0.0 (no live StoreKit flow wired)."
    ],
    ctaLabel: "Review Data trends"
  },
  "data-trends": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_trends-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_trends-660.jpg 660w, ./assets/screenshots/optimized/data_trends-990.jpg 990w",
    alt: "MindSense Data trends screen",
    title: "Pattern explorer for trend interpretation",
    description: "Trends workspace combines signal focus, windows, overlays, and confidence context to support action planning.",
    facts: [
      ["Windows", "7D, 14D, 30D"],
      ["Overlays", "Workouts, check-ins, experiments"],
      ["Export", "Filter sheet includes export payload controls"]
    ],
    bullets: [
      "Trend chart supports marker inspection and clear summary copy.",
      "Coverage diagnostics can be opened when reliability is low.",
      "Suggested plan route maps back into Regulate."
    ],
    ctaLabel: "Inspect experiment lifecycle"
  },
  "data-experiments": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_experiments-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_experiments-660.jpg 660w, ./assets/screenshots/optimized/data_experiments-990.jpg 990w",
    alt: "MindSense Data experiments screen",
    title: "Experiment lifecycle and adherence",
    description: "Experiments run as planned/active/completed objects with state-driven CTA changes and outcome capture.",
    facts: [
      ["Status model", "Planned, active, completed"],
      ["Cadence", "Daily logging through duration"],
      ["Completion", "Result sheet with keep/adjust/pause decisions"]
    ],
    bullets: [
      "Active experiment CTA adapts to day logging vs completion state.",
      "Adherence affects confidence progression and narrative signals.",
      "Result saves create history events and insight entries."
    ],
    ctaLabel: "Open Data history"
  },
  "data-history": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_history-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_history-660.jpg 660w, ./assets/screenshots/optimized/data_history-990.jpg 990w",
    alt: "MindSense Data history screen",
    title: "Weekly summary and event timeline",
    description: "History groups wins, risks, event chronology, and attribution follow-up workflows.",
    facts: [
      ["Weekly summary", "Wins, risks, next best action"],
      ["Timeline source", "Sessions, check-ins, experiments, system events"],
      ["Edit-later", "Attribution review path for recent episodes"]
    ],
    bullets: [
      "History keeps event context readable by day groups.",
      "Attribution edits can be reopened without disrupting active sessions.",
      "Pairs with what-is-working outputs for trend review."
    ],
    ctaLabel: "Inspect Settings"
  },
  settings: {
    kicker: "Settings",
    image: "./assets/screenshots/optimized/settings-660.jpg",
    srcset: "./assets/screenshots/optimized/settings-660.jpg 660w, ./assets/screenshots/optimized/settings-990.jpg 990w",
    alt: "MindSense Settings screen",
    title: "Privacy, health controls, notifications, and safety",
    description: "Settings centralizes preference autosave, health diagnostics controls, account access, and crisis safety pathways.",
    facts: [
      ["Autosave", "Setting changes persist immediately"],
      ["Health controls", "Resync, rebuild baseline, delete derived data"],
      ["Safety", "US 988 crisis resource row + wellness boundary copy"]
    ],
    bullets: [
      "Privacy policy row points to the public website privacy route.",
      "Appearance, reduced motion, and haptics toggles are user controlled.",
      "Sign out resets session and core local seeded state."
    ],
    ctaLabel: "Contact the team"
  }
};

const tourTabs = Array.from(document.querySelectorAll(".tour-tab"));
const tourPanel = document.getElementById("tour-panel");
const tourImage = document.getElementById("tour-image");
const tourKicker = document.getElementById("tour-kicker");
const tourTitle = document.getElementById("tour-title");
const tourDescription = document.getElementById("tour-description");
const tourFacts = document.getElementById("tour-facts");
const tourBullets = document.getElementById("tour-bullets");
const tourCTA = document.getElementById("tour-cta");

const renderTour = (screenKey) => {
  const payload = tourData[screenKey];
  if (!payload || !tourImage || !tourKicker || !tourTitle || !tourDescription || !tourFacts || !tourBullets) {
    return;
  }

  tourImage.src = payload.image;
  tourImage.srcset = payload.srcset;
  tourImage.alt = payload.alt;

  tourKicker.textContent = payload.kicker;
  tourTitle.textContent = payload.title;
  tourDescription.textContent = payload.description;

  tourFacts.innerHTML = payload.facts
    .map(([label, value]) => `<div><dt>${label}</dt><dd>${value}</dd></div>`)
    .join("");
  tourBullets.innerHTML = payload.bullets.map((line) => `<li>${line}</li>`).join("");

  if (tourCTA) {
    tourCTA.textContent = payload.ctaLabel;
  }

  tourTabs.forEach((tab) => {
    const active = tab.dataset.screen === screenKey;
    tab.classList.toggle("is-active", active);
    tab.setAttribute("aria-selected", active ? "true" : "false");
    tab.setAttribute("tabindex", active ? "0" : "-1");
  });

  if (tourPanel) {
    const activeTab = tourTabs.find((tab) => tab.dataset.screen === screenKey);
    if (activeTab?.id) {
      tourPanel.setAttribute("aria-labelledby", activeTab.id);
    }
  }
};

if (tourTabs.length > 0) {
  renderTour("intro");

  tourTabs.forEach((tab, index) => {
    tab.addEventListener("click", () => {
      const screen = tab.dataset.screen;
      if (screen) {
        renderTour(screen);
      }
    });

    tab.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }

      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        const screen = tab.dataset.screen;
        if (screen) {
          renderTour(screen);
        }
        return;
      }

      let target = index;
      if (event.key === "ArrowRight") {
        target = (index + 1) % tourTabs.length;
      } else if (event.key === "ArrowLeft") {
        target = (index - 1 + tourTabs.length) % tourTabs.length;
      } else if (event.key === "Home") {
        target = 0;
      } else if (event.key === "End") {
        target = tourTabs.length - 1;
      }

      const nextTab = tourTabs[target];
      nextTab?.focus();
      if (nextTab?.dataset.screen) {
        renderTour(nextTab.dataset.screen);
      }
    });
  });
}

const audienceData = {
  users: {
    kicker: "For prospective users",
    title: "One action path when your nervous system feels noisy.",
    description:
      "MindSense helps users decide quickly: read state, run one short protocol, and log whether it helped.",
    bullets: [
      "Designed to surface one next action without hunting through menus.",
      "Regulate sessions are short and guided, with visible progress states.",
      "Data views make it easier to see which routines are actually helping."
    ],
    ctaLabel: "Join waitlist",
    ctaHref: "mailto:hello@mindsense.ai?subject=MindSense%20User%20Waitlist"
  },
  stakeholders: {
    kicker: "For stakeholders",
    title: "Trust-forward implementation and measurable quality posture.",
    description:
      "Stakeholder review can focus on real runtime behavior, safety boundaries, and repeatable QA gates.",
    bullets: [
      "Local-first model with explicit confidence and coverage framing.",
      "Quality scripts and UI tests validate accessibility, contrast, and latency budgets.",
      "Scope boundaries are explicit: latent modules are separated from production navigation."
    ],
    ctaLabel: "Request pilot",
    ctaHref: "mailto:partnerships@mindsense.ai?subject=MindSense%20Stakeholder%20Pilot%20Request"
  },
  investors: {
    kicker: "For investors",
    title: "Execution evidence first, roadmap second.",
    description:
      "The current build already demonstrates loop discipline, deterministic engines, and instrumentation for diligence.",
    bullets: [
      "Recommendation, delta, and health-signal simulation engines are implemented and test-covered.",
      "Post-activation monetization surface exists, while billing integration remains explicitly unshipped.",
      "Clear milestone path from simulated stack to integrated production services."
    ],
    ctaLabel: "Investor channel",
    ctaHref: "mailto:investors@mindsense.ai?subject=MindSense%20Investor%20Inquiry"
  }
};

const audienceTabs = Array.from(document.querySelectorAll(".audience-tab"));
const audienceKicker = document.getElementById("audience-kicker");
const audienceTitle = document.getElementById("audience-title");
const audienceDescription = document.getElementById("audience-description");
const audienceBullets = document.getElementById("audience-bullets");
const audienceCTA = document.getElementById("audience-cta");

const renderAudience = (audienceKey) => {
  const payload = audienceData[audienceKey];
  if (!payload || !audienceKicker || !audienceTitle || !audienceDescription || !audienceBullets || !audienceCTA) {
    return;
  }

  audienceKicker.textContent = payload.kicker;
  audienceTitle.textContent = payload.title;
  audienceDescription.textContent = payload.description;
  audienceBullets.innerHTML = payload.bullets.map((line) => `<li>${line}</li>`).join("");
  audienceCTA.textContent = payload.ctaLabel;
  audienceCTA.href = payload.ctaHref;

  audienceTabs.forEach((tab) => {
    const active = tab.dataset.audience === audienceKey;
    tab.classList.toggle("is-active", active);
    tab.setAttribute("aria-selected", active ? "true" : "false");
    tab.setAttribute("tabindex", active ? "0" : "-1");
  });
};

if (audienceTabs.length > 0) {
  renderAudience("users");

  audienceTabs.forEach((tab, index) => {
    tab.addEventListener("click", () => {
      const key = tab.dataset.audience;
      if (key) {
        renderAudience(key);
      }
    });

    tab.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }

      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        const key = tab.dataset.audience;
        if (key) {
          renderAudience(key);
        }
        return;
      }

      let target = index;
      if (event.key === "ArrowRight") {
        target = (index + 1) % audienceTabs.length;
      } else if (event.key === "ArrowLeft") {
        target = (index - 1 + audienceTabs.length) % audienceTabs.length;
      } else if (event.key === "Home") {
        target = 0;
      } else if (event.key === "End") {
        target = audienceTabs.length - 1;
      }

      const nextTab = audienceTabs[target];
      nextTab?.focus();
      if (nextTab?.dataset.audience) {
        renderAudience(nextTab.dataset.audience);
      }
    });
  });
}

const heroStage = document.getElementById("hero-stage");
if (heroStage && !prefersReducedMotion) {
  const phones = Array.from(heroStage.querySelectorAll(".phone"));
  heroStage.addEventListener("pointermove", (event) => {
    const rect = heroStage.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width - 0.5;
    const y = (event.clientY - rect.top) / rect.height - 0.5;

    phones.forEach((phone, index) => {
      const depth = index + 1;
      const moveX = x * 11 * depth;
      const moveY = y * 8 * depth;
      phone.style.translate = `${moveX}px ${moveY}px`;
    });
  });

  heroStage.addEventListener("pointerleave", () => {
    phones.forEach((phone) => {
      phone.style.translate = "0 0";
    });
  });
}

const revealNodes = Array.from(document.querySelectorAll(".reveal"));
const revealNow = (node) => node.classList.add("is-visible");

if (prefersReducedMotion) {
  revealNodes.forEach((node) => revealNow(node));
} else if (window.gsap && window.ScrollTrigger) {
  window.gsap.registerPlugin(window.ScrollTrigger);

  window.gsap.from(".hero-copy > *", {
    y: 20,
    opacity: 0,
    duration: 0.82,
    ease: "power2.out",
    stagger: 0.1
  });

  window.gsap.from(".hero-stage .phone", {
    y: 26,
    opacity: 0,
    duration: 0.94,
    ease: "power3.out",
    stagger: 0.11
  });

  revealNodes.forEach((node) => {
    window.gsap.fromTo(
      node,
      { y: 24, opacity: 0 },
      {
        y: 0,
        opacity: 1,
        duration: 0.72,
        ease: "power2.out",
        scrollTrigger: {
          trigger: node,
          start: "top 82%",
          once: true
        }
      }
    );
  });
} else if ("IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return;
        }
        revealNow(entry.target);
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.16 }
  );

  revealNodes.forEach((node) => revealObserver.observe(node));
} else {
  revealNodes.forEach((node) => revealNow(node));
}

const copyright = document.getElementById("copyright");
if (copyright) {
  copyright.textContent = `© ${new Date().getFullYear()} MindSense AI. All rights reserved.`;
}
