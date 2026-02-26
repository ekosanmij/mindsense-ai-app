const prefersReducedMotion =
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const navToggle = document.querySelector(".nav-toggle");
const nav = document.querySelector(".site-nav");
const header = document.querySelector(".site-header");
const navLinks = document.querySelectorAll('.site-nav a[href^="#"]');
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

  navLinks.forEach((link) => link.addEventListener("click", closeNav));

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
  const ratio = scrollHeight <= 0 ? 0 : Math.min(Math.max(scrollTop / scrollHeight, 0), 1);
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
        if (!id || !sectionLinkMap.has(id)) {
          return;
        }
        if (entry.isIntersecting) {
          sectionLinkMap.forEach((node) => node.removeAttribute("aria-current"));
          sectionLinkMap.get(id)?.setAttribute("aria-current", "page");
        }
      });
    },
    {
      rootMargin: "-30% 0px -50% 0px",
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

const metrics = Array.from(document.querySelectorAll(".metric[data-count]"));

const animateCount = (node) => {
  const target = Number(node.dataset.count || 0);
  if (!Number.isFinite(target)) {
    return;
  }

  if (prefersReducedMotion) {
    node.textContent = target.toLocaleString();
    return;
  }

  const durationMs = 1100;
  const start = performance.now();

  const tick = (now) => {
    const elapsed = now - start;
    const progress = Math.min(elapsed / durationMs, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    const value = Math.round(target * eased);
    node.textContent = value.toLocaleString();

    if (progress < 1) {
      window.requestAnimationFrame(tick);
    }
  };

  window.requestAnimationFrame(tick);
};

if ("IntersectionObserver" in window && metrics.length > 0) {
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
    { threshold: 0.35 }
  );

  metrics.forEach((metric) => metricObserver.observe(metric));
} else {
  metrics.forEach((metric) => animateCount(metric));
}

const loopData = [
  {
    kicker: "Step 1",
    title: "Today: state snapshot and action command deck",
    copy: "Today gives one recommendation path while still exposing confidence, coverage, and diagnostic context.",
    points: [
      "Load, Readiness, and Consistency are surfaced first.",
      "One recommended next protocol stays dominant.",
      "Context capture is available for recent unlabelled stress episodes."
    ]
  },
  {
    kicker: "Step 2",
    title: "Regulate: guided protocol execution",
    copy: "Users select a ranked protocol, run a focused timer flow, and stay inside minimal-distraction execution.",
    points: [
      "Three protocol families: Calm now, Focus prep, Sleep downshift.",
      "Session transitions from selection to timer to impact capture.",
      "Tab behavior and CTA framing preserve flow clarity."
    ]
  },
  {
    kicker: "Step 3",
    title: "Impact capture closes the loop",
    copy: "Post-session check-in captures perceived helpfulness and estimated physiological direction.",
    points: [
      "Outcome recording updates metric trajectories deterministically.",
      "Session history and event history are appended immediately.",
      "Confidence can increase as repeat loops and adherence improve."
    ]
  },
  {
    kicker: "Step 4",
    title: "Data consolidates trends, experiments, and history",
    copy: "Users and teams can inspect directional patterns and experiment adherence over time.",
    points: [
      "Trend windows include 7D, 14D, and 30D views.",
      "Experiments support planned, active, and completed lifecycle states.",
      "Weekly summary surfaces wins, risks, and next best action."
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
  loopPoints.innerHTML = payload.points.map((line) => `<li>${line}</li>`).join("");

  loopStepNodes.forEach((node, index) => {
    const isActive = index === loopIndex;
    node.classList.toggle("is-active", isActive);
    node.setAttribute("tabindex", isActive ? "0" : "-1");
    node.setAttribute("aria-pressed", isActive ? "true" : "false");
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

      let targetIndex = index;
      if (event.key === "ArrowRight") {
        targetIndex = (index + 1) % loopStepNodes.length;
      } else if (event.key === "ArrowLeft") {
        targetIndex = (index - 1 + loopStepNodes.length) % loopStepNodes.length;
      } else if (event.key === "Home") {
        targetIndex = 0;
      } else if (event.key === "End") {
        targetIndex = loopStepNodes.length - 1;
      }

      renderLoop(targetIndex);
      loopStepNodes[targetIndex]?.focus();
    });
  });

  loopNextButton?.addEventListener("click", () => renderLoop(loopIndex + 1));

  if (!prefersReducedMotion && "IntersectionObserver" in window) {
    const loopRoot = document.getElementById("loop-steps");
    if (loopRoot) {
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
        { threshold: 0.58 }
      );
      loopObserver.observe(loopRoot);
    }
  }
}

const tourData = {
  intro: {
    kicker: "Entry",
    image: "./assets/screenshots/optimized/intro-660.jpg",
    srcset: "./assets/screenshots/optimized/intro-660.jpg 660w, ./assets/screenshots/optimized/intro-990.jpg 990w",
    alt: "MindSense intro screen",
    title: "Intro and trust framing",
    description: "Introduces the product promise and starts the Apple sign-in path with minimal friction.",
    metadata: [
      ["Primary job", "Frame value and trust before account session."],
      ["Primary CTA", "Continue with Apple"],
      ["Position in flow", "Launch -> Intro -> Auth"]
    ],
    bullets: [
      "Highlights state, action, and rationale model.",
      "Keeps copy concise and confidence-forward.",
      "Designed for completion in under a minute."
    ],
    ctaLabel: "See onboarding activation"
  },
  onboarding: {
    kicker: "Activation",
    image: "./assets/screenshots/optimized/onboarding-660.jpg",
    srcset: "./assets/screenshots/optimized/onboarding-660.jpg 660w, ./assets/screenshots/optimized/onboarding-990.jpg 990w",
    alt: "MindSense onboarding screen",
    title: "Onboarding with required activation steps",
    description: "Activation focuses baseline + first check-in and routes to main tabs once complete.",
    metadata: [
      ["Required steps", "Start baseline, complete first check-in"],
      ["Optional setup", "Permissions can be configured later"],
      ["Escalation", "High check-in values trigger guidance"]
    ],
    bullets: [
      "Progress rail keeps completion state explicit.",
      "Required steps are sequentially gated.",
      "Transition to ready state is deterministic."
    ],
    ctaLabel: "Explore Today command deck"
  },
  today: {
    kicker: "Today",
    image: "./assets/screenshots/optimized/today-660.jpg",
    srcset: "./assets/screenshots/optimized/today-660.jpg 660w, ./assets/screenshots/optimized/today-990.jpg 990w",
    alt: "MindSense today screen",
    title: "State snapshot and best-next-action surface",
    description: "Today prioritizes one action path while preserving drivers, timeline, diagnostics, and confidence framing.",
    metadata: [
      ["Primary metrics", "Load, Readiness, Consistency"],
      ["Recommendation", "One mapped protocol with expected effect"],
      ["Fallback mode", "Low coverage prompts check-in-first behavior"]
    ],
    bullets: [
      "Sticky continue-session dock appears when a session is active.",
      "Timeline and episode context capture stay accessible.",
      "Confidence and coverage labels remain visible for interpretation quality."
    ],
    ctaLabel: "See Regulate protocol selection"
  },
  "regulate-select": {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_select-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_select-660.jpg 660w, ./assets/screenshots/optimized/regulate_select-990.jpg 990w",
    alt: "MindSense regulate protocol selection screen",
    title: "Protocol selection with ranked presets",
    description: "Regulate starts with scenario-sensitive protocol ranking and guided step progression.",
    metadata: [
      ["Preset catalog", "Calm now, Focus prep, Sleep downshift"],
      ["Guided model", "Select -> Run -> Record"],
      ["Selection signal", "Ranking adapts via recommendation engine"]
    ],
    bullets: [
      "Preset metadata includes duration and why-now rationale.",
      "Action path is narrow and low-friction.",
      "Supports active-session resume behavior from Today."
    ],
    ctaLabel: "Inspect run-timer phase"
  },
  "regulate-run": {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_run-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_run-660.jpg 660w, ./assets/screenshots/optimized/regulate_run-990.jpg 990w",
    alt: "MindSense regulate run timer screen",
    title: "Run timer and impact capture",
    description: "Timer execution transitions into post-session impact capture and updates metrics/history on submit.",
    metadata: [
      ["Runtime behavior", "Timer ticks every second"],
      ["Outcome capture", "Helpfulness + directional impact"],
      ["Post-action", "May present post-activation paywall"]
    ],
    bullets: [
      "Session completion writes outcome to local history.",
      "Effect metrics include downshift and recovery slope models.",
      "Tab bar behavior adapts for focused in-session UX."
    ],
    ctaLabel: "Move to trends analysis"
  },
  "data-trends": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_trends-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_trends-660.jpg 660w, ./assets/screenshots/optimized/data_trends-990.jpg 990w",
    alt: "MindSense data trends screen",
    title: "Trends workspace with signal overlays",
    description: "Trend views combine windows, overlays, and confidence readouts to support pattern interpretation.",
    metadata: [
      ["Windows", "7D, 14D, 30D"],
      ["Overlays", "Sessions, check-ins, experiments"],
      ["Focus", "Readiness/Load/Consistency signal pivots"]
    ],
    bullets: [
      "Interactive selection markers support deeper chart reading.",
      "Confidence diagnostics can be inspected in detail.",
      "Suggested plan CTA routes into Regulate."
    ],
    ctaLabel: "Review experiment lifecycle"
  },
  "data-experiments": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_experiments-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_experiments-660.jpg 660w, ./assets/screenshots/optimized/data_experiments-990.jpg 990w",
    alt: "MindSense data experiments screen",
    title: "Experiments workspace for behavior testing",
    description: "Experiments track adherence and outcomes across planned, active, and completed states.",
    metadata: [
      ["States", "Planned, active, completed"],
      ["Cadence", "Daily logging across duration window"],
      ["Completion", "Summary sheet with keep/adjust decisions"]
    ],
    bullets: [
      "CTA changes dynamically by experiment state.",
      "Adherence influences confidence progression.",
      "Results roll into narrative summaries and history."
    ],
    ctaLabel: "Open history insights"
  },
  "data-history": {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_history-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_history-660.jpg 660w, ./assets/screenshots/optimized/data_history-990.jpg 990w",
    alt: "MindSense data history screen",
    title: "History and weekly summary",
    description: "History consolidates wins, risks, timeline events, and what-is-working summaries.",
    metadata: [
      ["Summary model", "Wins, risks, next best action"],
      ["Timeline", "Grouped events with typed markers"],
      ["Learning output", "Top protocol, top trigger, recovery window"]
    ],
    bullets: [
      "Keeps historical context scannable for daily review.",
      "Pairs with experiment outcomes for decision quality.",
      "Supports stakeholder narrative generation."
    ],
    ctaLabel: "Inspect settings and controls"
  },
  settings: {
    kicker: "Settings",
    image: "./assets/screenshots/optimized/settings-660.jpg",
    srcset: "./assets/screenshots/optimized/settings-660.jpg 660w, ./assets/screenshots/optimized/settings-990.jpg 990w",
    alt: "MindSense settings screen",
    title: "Account, preferences, health controls, and safety",
    description: "Settings centralizes preferences with autosave behavior and signal-source diagnostics.",
    metadata: [
      ["Persistence", "Autosave tracked with analytics events"],
      ["Safety", "In-app crisis support shortcut"],
      ["Privacy link", "Web privacy route reachable from settings"]
    ],
    bullets: [
      "Supports appearance, motion, haptics, and quiet-hour preferences.",
      "Exposes health diagnostics and rebuild/delete derived data actions.",
      "Sign-out clears session and seeded local state."
    ],
    ctaLabel: "Talk with the team"
  }
};

const tourTabs = Array.from(document.querySelectorAll(".tour-tab"));
const tourImage = document.getElementById("tour-image");
const tourKicker = document.getElementById("tour-kicker");
const tourTitle = document.getElementById("tour-title");
const tourDescription = document.getElementById("tour-description");
const tourBullets = document.getElementById("tour-bullets");
const tourMetadata = document.getElementById("tour-metadata");
const tourCTA = document.getElementById("tour-cta");
const tourPanel = document.getElementById("tour-panel");

const renderTour = (screenKey) => {
  const payload = tourData[screenKey];
  if (!payload || !tourImage || !tourKicker || !tourTitle || !tourDescription || !tourBullets || !tourMetadata) {
    return;
  }

  tourImage.src = payload.image;
  tourImage.srcset = payload.srcset;
  tourImage.alt = payload.alt;

  tourKicker.textContent = payload.kicker;
  tourTitle.textContent = payload.title;
  tourDescription.textContent = payload.description;

  tourMetadata.innerHTML = payload.metadata
    .map(
      ([label, value]) =>
        `<div><dt>${label}</dt><dd>${value}</dd></div>`
    )
    .join("");

  tourBullets.innerHTML = payload.bullets.map((line) => `<li>${line}</li>`).join("");
  if (tourCTA) {
    tourCTA.textContent = payload.ctaLabel;
  }

  tourTabs.forEach((tab) => {
    const isActive = tab.dataset.screen === screenKey;
    tab.classList.toggle("is-active", isActive);
    tab.setAttribute("aria-selected", isActive ? "true" : "false");
    tab.setAttribute("tabindex", isActive ? "0" : "-1");
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

      let targetIndex = index;
      if (event.key === "ArrowRight") {
        targetIndex = (index + 1) % tourTabs.length;
      } else if (event.key === "ArrowLeft") {
        targetIndex = (index - 1 + tourTabs.length) % tourTabs.length;
      } else if (event.key === "Home") {
        targetIndex = 0;
      } else if (event.key === "End") {
        targetIndex = tourTabs.length - 1;
      }

      const target = tourTabs[targetIndex];
      target.focus();
      if (target.dataset.screen) {
        renderTour(target.dataset.screen);
      }
    });
  });
}

const audienceData = {
  users: {
    kicker: "For users",
    title: "Regulation support with low cognitive overhead",
    description:
      "MindSense minimizes decision fatigue by delivering one clear action, guided execution, and immediate reflection loops.",
    bullets: [
      "Primary loop supports state understanding in roughly 30 seconds.",
      "Guided session flow simplifies protocol execution and follow-through.",
      "Data workspace reinforces what is working across days and contexts."
    ],
    ctaLabel: "Join waitlist",
    ctaHref: "mailto:hello@mindsense.ai?subject=MindSense%20Waitlist%20Request"
  },
  stakeholders: {
    kicker: "For stakeholders",
    title: "Operational clarity with trust-forward implementation",
    description:
      "Stakeholders can evaluate architecture posture, quality workflows, and safety boundaries without relying on speculative claims.",
    bullets: [
      "Core behavior is local-first with explicit confidence/coverage communication.",
      "Quality gates are encoded in scripts and UI tests for repeatable validation.",
      "Feature-flagged latent modules are clearly separated from production IA."
    ],
    ctaLabel: "Request stakeholder pilot",
    ctaHref:
      "mailto:partnerships@mindsense.ai?subject=MindSense%20Stakeholder%20Pilot%20Request"
  },
  investors: {
    kicker: "For investors",
    title: "Execution depth with visible commercialization path",
    description:
      "The product already demonstrates disciplined loop design, instrumentation, and platform quality systems, with clear next integration milestones.",
    bullets: [
      "KPI scorecard model tracks activation, retention, session starts, and completion.",
      "Recommendation and simulation engines are deterministic and test-covered.",
      "Post-activation paywall and trial narrative exist for monetization progression."
    ],
    ctaLabel: "Open investor channel",
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
      const audience = tab.dataset.audience;
      if (audience) {
        renderAudience(audience);
      }
    });

    tab.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }
      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        const audience = tab.dataset.audience;
        if (audience) {
          renderAudience(audience);
        }
        return;
      }

      let targetIndex = index;
      if (event.key === "ArrowRight") {
        targetIndex = (index + 1) % audienceTabs.length;
      } else if (event.key === "ArrowLeft") {
        targetIndex = (index - 1 + audienceTabs.length) % audienceTabs.length;
      } else if (event.key === "Home") {
        targetIndex = 0;
      } else if (event.key === "End") {
        targetIndex = audienceTabs.length - 1;
      }

      const target = audienceTabs[targetIndex];
      target.focus();
      if (target.dataset.audience) {
        renderAudience(target.dataset.audience);
      }
    });
  });
}

const roadmapSteps = Array.from(document.querySelectorAll(".roadmap-step"));
let roadmapIndex = 0;
let roadmapIntervalId = null;

const renderRoadmap = (nextIndex) => {
  if (roadmapSteps.length === 0) {
    return;
  }

  roadmapIndex = ((nextIndex % roadmapSteps.length) + roadmapSteps.length) % roadmapSteps.length;

  roadmapSteps.forEach((step, index) => {
    step.classList.toggle("is-active", index === roadmapIndex);
  });
};

if (roadmapSteps.length > 0) {
  renderRoadmap(0);

  roadmapSteps.forEach((step, index) => {
    step.addEventListener("mouseenter", () => renderRoadmap(index));
    step.addEventListener("focusin", () => renderRoadmap(index));
  });

  if (!prefersReducedMotion && "IntersectionObserver" in window) {
    const roadmapRoot = document.getElementById("roadmap-shell");
    if (roadmapRoot) {
      const roadmapObserver = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) {
              if (roadmapIntervalId) {
                window.clearInterval(roadmapIntervalId);
                roadmapIntervalId = null;
              }
              return;
            }

            if (!roadmapIntervalId) {
              roadmapIntervalId = window.setInterval(() => renderRoadmap(roadmapIndex + 1), 2600);
            }
          });
        },
        { threshold: 0.45 }
      );
      roadmapObserver.observe(roadmapRoot);
    }
  }
}

const heroStage = document.getElementById("hero-stage");
if (heroStage && !prefersReducedMotion) {
  const cards = Array.from(heroStage.querySelectorAll(".phone-card"));

  heroStage.addEventListener("pointermove", (event) => {
    const rect = heroStage.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width - 0.5;
    const y = (event.clientY - rect.top) / rect.height - 0.5;

    cards.forEach((card, index) => {
      const depth = index + 1;
      const moveX = x * 10 * depth;
      const moveY = y * 8 * depth;
      card.style.translate = `${moveX}px ${moveY}px`;
    });
  });

  heroStage.addEventListener("pointerleave", () => {
    cards.forEach((card) => {
      card.style.translate = "0 0";
    });
  });
}

const revealNodes = Array.from(document.querySelectorAll(".reveal"));

const setRevealed = (node) => {
  node.classList.add("is-visible");
};

if (prefersReducedMotion) {
  revealNodes.forEach((node) => setRevealed(node));
} else if (window.gsap && window.ScrollTrigger) {
  window.gsap.registerPlugin(window.ScrollTrigger);

  window.gsap.from(".hero-copy > *", {
    y: 18,
    opacity: 0,
    duration: 0.8,
    stagger: 0.1,
    ease: "power2.out"
  });

  window.gsap.from(".hero-stage .phone-card", {
    y: 26,
    opacity: 0,
    duration: 0.95,
    stagger: 0.11,
    ease: "power3.out"
  });

  revealNodes.forEach((node) => {
    window.gsap.fromTo(
      node,
      { y: 24, opacity: 0 },
      {
        y: 0,
        opacity: 1,
        duration: 0.7,
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
        setRevealed(entry.target);
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.16 }
  );

  revealNodes.forEach((node) => revealObserver.observe(node));
} else {
  revealNodes.forEach((node) => setRevealed(node));
}

const copyrightNode = document.getElementById("copyright");
if (copyrightNode) {
  copyrightNode.textContent = `© ${new Date().getFullYear()} MindSense AI. All rights reserved.`;
}
