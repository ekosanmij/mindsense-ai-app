const prefersReducedMotion =
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const navToggle = document.querySelector(".nav-toggle");
const nav = document.querySelector(".site-nav");
const header = document.querySelector(".site-header");
const navLinks = document.querySelectorAll('.site-nav a[href^="#"]');

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
    link.addEventListener("click", () => closeNav());
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
      rootMargin: "-30% 0px -55% 0px",
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

const personaData = {
  user: {
    title: "Nervous-system guidance that turns signals into one clear next action.",
    copy: "MindSense helps people read current state, run one short protocol, and learn what works over time. The core loop is local-first and trust-forward by design.",
    primaryCta: {
      label: "Join waitlist",
      href: "mailto:hello@mindsense.ai?subject=MindSense%20Waitlist%20Request"
    },
    secondaryCta: {
      label: "Book product walkthrough",
      href: "mailto:partnerships@mindsense.ai?subject=MindSense%20Product%20Demo%20Request"
    },
    tags: ["Local-first runtime", "Sign in with Apple", "Deterministic QA gates"]
  },
  stakeholder: {
    title: "A wellness platform stakeholders can evaluate with clear implementation boundaries.",
    copy: "MindSense combines user-facing guidance with transparency around confidence, data coverage, and safety framing to support responsible pilots and partner reviews.",
    primaryCta: {
      label: "Request stakeholder pilot",
      href: "mailto:partnerships@mindsense.ai?subject=MindSense%20Stakeholder%20Pilot%20Request"
    },
    secondaryCta: {
      label: "Review governance posture",
      href: "#evidence"
    },
    tags: ["Confidence diagnostics", "Safety escalation framing", "Quality gate evidence"]
  },
  investor: {
    title: "An execution-focused product story with measurable loops and diligence-ready artifacts.",
    copy: "MindSense is positioned around repeatable behavior loops, deterministic QA instrumentation, and KPI narratives that can be reviewed directly against shipped product flows.",
    primaryCta: {
      label: "Contact investor relations",
      href: "mailto:investors@mindsense.ai?subject=MindSense%20Investor%20Inquiry"
    },
    secondaryCta: {
      label: "Explore KPI evidence",
      href: "#audiences"
    },
    tags: ["Activation + retention KPIs", "Automated screenshot export", "Local-first product posture"]
  }
};

const personaButtons = Array.from(document.querySelectorAll(".persona-btn"));
const personaTitle = document.getElementById("persona-title");
const personaCopy = document.getElementById("persona-copy");
const personaPrimaryCta = document.getElementById("persona-primary-cta");
const personaSecondaryCta = document.getElementById("persona-secondary-cta");
const personaTags = document.getElementById("persona-tags");

const renderPersona = (personaKey) => {
  const payload = personaData[personaKey];
  if (!payload || !personaTitle || !personaCopy || !personaPrimaryCta || !personaSecondaryCta || !personaTags) {
    return;
  }

  document.body.setAttribute("data-persona", personaKey);

  personaTitle.textContent = payload.title;
  personaCopy.textContent = payload.copy;

  personaPrimaryCta.textContent = payload.primaryCta.label;
  personaPrimaryCta.setAttribute("href", payload.primaryCta.href);

  personaSecondaryCta.textContent = payload.secondaryCta.label;
  personaSecondaryCta.setAttribute("href", payload.secondaryCta.href);

  const tagNodes = payload.tags.map((item) => {
    const li = document.createElement("li");
    li.textContent = item;
    return li;
  });
  personaTags.replaceChildren(...tagNodes);
};

if (personaButtons.length > 0) {
  const activatePersona = (nextButton, shouldFocus = false) => {
    if (!nextButton) {
      return;
    }

    personaButtons.forEach((button) => {
      const active = button === nextButton;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-selected", active ? "true" : "false");
      if (active && shouldFocus) {
        button.focus();
      }
    });

    const personaKey = nextButton.getAttribute("data-persona");
    renderPersona(personaKey);
  };

  const defaultButton = personaButtons.find((node) => node.classList.contains("is-active")) || personaButtons[0];
  activatePersona(defaultButton, false);

  personaButtons.forEach((button, index) => {
    button.addEventListener("click", () => activatePersona(button, false));

    button.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }

      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        activatePersona(button, false);
        return;
      }

      let targetIndex = index;
      if (event.key === "ArrowRight") {
        targetIndex = (index + 1) % personaButtons.length;
      } else if (event.key === "ArrowLeft") {
        targetIndex = (index - 1 + personaButtons.length) % personaButtons.length;
      } else if (event.key === "Home") {
        targetIndex = 0;
      } else if (event.key === "End") {
        targetIndex = personaButtons.length - 1;
      }

      activatePersona(personaButtons[targetIndex], true);
    });
  });
}

const loopData = [
  {
    kicker: "Step 1",
    title: "Read state quickly on Today",
    copy: "The command deck keeps one primary path visible while preserving confidence context, top drivers, and timeline insights."
  },
  {
    kicker: "Step 2",
    title: "Run one protocol in Regulate",
    copy: "Select, Run, and Record flow guides a short intervention session with timer pacing and reduced navigation noise."
  },
  {
    kicker: "Step 3",
    title: "Capture immediate impact",
    copy: "Post-session check-in captures helpfulness and direction so deterministic deltas can adjust state and recommendation quality."
  },
  {
    kicker: "Step 4",
    title: "Review trends and experiments",
    copy: "Data surfaces behavior patterns, overlays event context, and supports focused experiments for incremental improvement."
  }
];

const loopStepNodes = Array.from(document.querySelectorAll(".loop-step"));
const loopKicker = document.getElementById("loop-kicker");
const loopTitle = document.getElementById("loop-title");
const loopCopy = document.getElementById("loop-copy");
const loopNextButton = document.getElementById("loop-next");

let loopIndex = 0;
let loopTimerId = null;

const renderLoop = (nextIndex) => {
  if (!loopKicker || !loopTitle || !loopCopy || loopStepNodes.length === 0) {
    return;
  }

  loopIndex = ((nextIndex % loopData.length) + loopData.length) % loopData.length;
  const payload = loopData[loopIndex];

  loopKicker.textContent = payload.kicker;
  loopTitle.textContent = payload.title;
  loopCopy.textContent = payload.copy;

  loopStepNodes.forEach((node, index) => {
    node.classList.toggle("is-active", index === loopIndex);
  });
};

if (loopStepNodes.length > 0) {
  renderLoop(0);

  loopStepNodes.forEach((node, index) => {
    node.addEventListener("click", () => renderLoop(index));
  });

  loopNextButton?.addEventListener("click", () => renderLoop(loopIndex + 1));

  if (!prefersReducedMotion && "IntersectionObserver" in window) {
    const loopObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) {
            if (loopTimerId) {
              window.clearInterval(loopTimerId);
              loopTimerId = null;
            }
            return;
          }

          if (!loopTimerId) {
            loopTimerId = window.setInterval(() => {
              renderLoop(loopIndex + 1);
            }, 5200);
          }
        });
      },
      { threshold: 0.55 }
    );

    const stepsRoot = document.getElementById("loop-steps");
    if (stepsRoot) {
      loopObserver.observe(stepsRoot);
    }
  }
}

const surfaceData = {
  today: {
    kicker: "Today",
    image: "./assets/screenshots/optimized/today-660.jpg",
    srcset:
      "./assets/screenshots/optimized/today-660.jpg 660w, ./assets/screenshots/optimized/today-990.jpg 990w",
    alt: "MindSense Today screen",
    title: "State + one next action",
    copy: "Today keeps one recommendation dominant while preserving diagnostics, driver context, and timeline evidence.",
    bullets: [
      "Load, Readiness, Consistency with metric deltas.",
      "Best-next-step card with rationale and expected effect.",
      "Timeline, stress-episode details, and quick context capture."
    ]
  },
  regulate: {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_run-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_run-660.jpg 660w, ./assets/screenshots/optimized/regulate_run-990.jpg 990w",
    alt: "MindSense Regulate run screen",
    title: "Protocol execution and impact recording",
    copy: "Regulate uses a three-step execution model: select protocol, run timer, and record perceived impact.",
    bullets: [
      "Preset ranking tied to intent mode and recommendation logic.",
      "Guided timer flow with low-noise interaction model.",
      "Outcome capture feeds deterministic state updates."
    ]
  },
  data: {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_trends-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_trends-660.jpg 660w, ./assets/screenshots/optimized/data_trends-990.jpg 990w",
    alt: "MindSense Data trends screen",
    title: "Patterns, overlays, and comparisons",
    copy: "Data Trends blends time windows, smoothing, day filters, and event overlays to expose behavior patterns.",
    bullets: [
      "7D / 14D / 30D trend windows.",
      "Check-ins, workouts, and experiments as visual overlays.",
      "Coverage-aware confidence context for interpretation."
    ]
  },
  history: {
    kicker: "History",
    image: "./assets/screenshots/optimized/data_history-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_history-660.jpg 660w, ./assets/screenshots/optimized/data_history-990.jpg 990w",
    alt: "MindSense Data history screen",
    title: "Traceable outcome history",
    copy: "History consolidates sessions, check-ins, and experiment events for attribution and review.",
    bullets: [
      "Chronological event stream with metadata context.",
      "Episode-level details for better pattern interpretation.",
      "Supports stakeholder reviews of usage quality."
    ]
  },
  onboarding: {
    kicker: "Onboarding",
    image: "./assets/screenshots/optimized/onboarding-660.jpg",
    srcset:
      "./assets/screenshots/optimized/onboarding-660.jpg 660w, ./assets/screenshots/optimized/onboarding-990.jpg 990w",
    alt: "MindSense Onboarding screen",
    title: "Activation in under 45 seconds",
    copy: "Onboarding keeps activation tight with required baseline + first check-in steps before entering main tabs.",
    bullets: [
      "Step model with deterministic progression.",
      "Escalation guidance appears on high load values.",
      "Optional permissions can be completed later in Settings."
    ]
  },
  settings: {
    kicker: "Settings",
    image: "./assets/screenshots/optimized/settings-660.jpg",
    srcset:
      "./assets/screenshots/optimized/settings-660.jpg 660w, ./assets/screenshots/optimized/settings-990.jpg 990w",
    alt: "MindSense Settings screen",
    title: "Privacy, notifications, and safety controls",
    copy: "Settings centralizes policy links, signal-source preferences, quiet hours, motion, and account access.",
    bullets: [
      "Privacy/data control pathways and health-permission entry.",
      "Notification preferences with quiet-hours scheduling.",
      "Safety actions including crisis shortcut context."
    ]
  }
};

const surfaceTabs = Array.from(document.querySelectorAll(".surface-tab"));
const surfaceImage = document.getElementById("surface-image");
const surfaceKicker = document.getElementById("surface-kicker");
const surfaceTitle = document.getElementById("surface-title");
const surfaceCopy = document.getElementById("surface-copy");
const surfaceBullets = document.getElementById("surface-bullets");
const surfacePanel = document.getElementById("surface-panel");

const renderSurface = (key) => {
  const payload = surfaceData[key];
  if (!payload || !surfaceImage || !surfaceKicker || !surfaceTitle || !surfaceCopy || !surfaceBullets) {
    return;
  }

  surfaceImage.src = payload.image;
  surfaceImage.srcset = payload.srcset;
  surfaceImage.alt = payload.alt;
  surfaceKicker.textContent = payload.kicker;
  surfaceTitle.textContent = payload.title;
  surfaceCopy.textContent = payload.copy;

  const bulletNodes = payload.bullets.map((item) => {
    const li = document.createElement("li");
    li.textContent = item;
    return li;
  });

  surfaceBullets.replaceChildren(...bulletNodes);
};

if (surfaceTabs.length > 0) {
  const activateTab = (nextTab, focusTab = false) => {
    if (!nextTab) {
      return;
    }

    surfaceTabs.forEach((tab) => {
      const active = tab === nextTab;
      tab.classList.toggle("is-active", active);
      tab.setAttribute("aria-selected", active ? "true" : "false");
      tab.setAttribute("tabindex", active ? "0" : "-1");
    });

    const key = nextTab.getAttribute("data-screen");
    renderSurface(key);

    if (surfacePanel && nextTab.id) {
      surfacePanel.setAttribute("aria-labelledby", nextTab.id);
    }

    if (focusTab) {
      nextTab.focus();
    }
  };

  const defaultTab = surfaceTabs.find((node) => node.classList.contains("is-active")) || surfaceTabs[0];
  activateTab(defaultTab, false);

  surfaceTabs.forEach((tab, index) => {
    tab.addEventListener("click", () => activateTab(tab, false));

    tab.addEventListener("keydown", (event) => {
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(event.key)) {
        return;
      }

      event.preventDefault();

      if (event.key === "Enter" || event.key === " ") {
        activateTab(tab, false);
        return;
      }

      let targetIndex = index;
      if (event.key === "ArrowRight") {
        targetIndex = (index + 1) % surfaceTabs.length;
      } else if (event.key === "ArrowLeft") {
        targetIndex = (index - 1 + surfaceTabs.length) % surfaceTabs.length;
      } else if (event.key === "Home") {
        targetIndex = 0;
      } else if (event.key === "End") {
        targetIndex = surfaceTabs.length - 1;
      }

      activateTab(surfaceTabs[targetIndex], true);
    });
  });
}

const metrics = document.querySelectorAll(".metric[data-count]");

const setMetricFinalValues = () => {
  metrics.forEach((node) => {
    const max = Number(node.getAttribute("data-count") || 0);
    node.textContent = String(max);
  });
};

const animateCounter = (node) => {
  const max = Number(node.getAttribute("data-count") || 0);
  if (!window.gsap || prefersReducedMotion) {
    node.textContent = String(max);
    return;
  }

  const tracker = { value: 0 };
  window.gsap.to(tracker, {
    value: max,
    duration: 1,
    ease: "power2.out",
    onUpdate: () => {
      node.textContent = String(Math.round(tracker.value));
    }
  });
};

if ("IntersectionObserver" in window) {
  const metricObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          animateCounter(entry.target);
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.5 }
  );

  metrics.forEach((metric) => metricObserver.observe(metric));
} else {
  setMetricFinalValues();
}

const ambientOrbs = Array.from(document.querySelectorAll(".ambient-orb"));
if (!prefersReducedMotion && ambientOrbs.length > 0) {
  window.addEventListener("pointermove", (event) => {
    const x = event.clientX / Math.max(window.innerWidth, 1);
    const y = event.clientY / Math.max(window.innerHeight, 1);

    ambientOrbs.forEach((orb, index) => {
      const depth = (index + 1) * 8;
      const moveX = (x - 0.5) * depth;
      const moveY = (y - 0.5) * depth;
      orb.style.transform = `translate(${moveX.toFixed(2)}px, ${moveY.toFixed(2)}px)`;
    });
  });
}

const revealNodes = document.querySelectorAll(".reveal");
if (prefersReducedMotion || !window.gsap || !window.ScrollTrigger) {
  revealNodes.forEach((node) => {
    node.style.opacity = "1";
    node.style.transform = "translateY(0)";
  });
} else {
  window.gsap.registerPlugin(window.ScrollTrigger);

  window.gsap.to(".shot-card-a", {
    y: -11,
    duration: 3.4,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut"
  });

  window.gsap.to(".shot-card-b", {
    y: 9,
    duration: 3.8,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut"
  });

  window.gsap.to(".shot-card-c", {
    y: -8,
    duration: 3.2,
    repeat: -1,
    yoyo: true,
    ease: "sine.inOut"
  });

  window.gsap.utils.toArray(".reveal").forEach((element) => {
    window.gsap.fromTo(
      element,
      { opacity: 0, y: 24 },
      {
        opacity: 1,
        y: 0,
        duration: 0.8,
        ease: "power2.out",
        scrollTrigger: {
          trigger: element,
          start: "top 84%"
        }
      }
    );
  });
}

const yearNode = document.getElementById("copyright");
if (yearNode) {
  yearNode.textContent = `\u00a9 ${new Date().getFullYear()} MindSense AI`;
}
