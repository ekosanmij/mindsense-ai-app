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

const loopData = [
  {
    kicker: "Step 1",
    title: "Today: state and recommendation",
    copy: "The command deck keeps one action path visible while preserving confidence context and signal diagnostics."
  },
  {
    kicker: "Step 2",
    title: "Regulate: guided protocol execution",
    copy: "Users select a ranked protocol, run the timer, and stay in a focused execution flow."
  },
  {
    kicker: "Step 3",
    title: "Impact capture closes the loop",
    copy: "Post-session check-in captures perceived effect and updates deterministic model state."
  },
  {
    kicker: "Step 4",
    title: "Data: trends and experiments",
    copy: "Trends, overlays, and experiment workspaces support better day-over-day regulation decisions."
  }
];

const loopStepNodes = Array.from(document.querySelectorAll(".loop-step"));
const loopKicker = document.getElementById("loop-kicker");
const loopTitle = document.getElementById("loop-title");
const loopCopy = document.getElementById("loop-copy");
const loopNextButton = document.getElementById("loop-next");

let loopIndex = 0;
let loopIntervalId = null;

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
    const active = index === loopIndex;
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
              loopIntervalId = window.setInterval(() => renderLoop(loopIndex + 1), 5500);
            }
          });
        },
        { threshold: 0.55 }
      );
      loopObserver.observe(loopRoot);
    }
  }
}

const surfaceData = {
  intro: {
    kicker: "Intro",
    image: "./assets/screenshots/optimized/intro-660.jpg",
    srcset: "./assets/screenshots/optimized/intro-660.jpg 660w, ./assets/screenshots/optimized/intro-990.jpg 990w",
    alt: "MindSense intro screen",
    title: "Promise and trust framing",
    description: "Sets product value and trust posture before authentication.",
    bullets: [
      "Highlights: status, action, rationale.",
      "Sign in with Apple entry point.",
      "Low-friction start into onboarding."
    ]
  },
  onboarding: {
    kicker: "Onboarding",
    image: "./assets/screenshots/optimized/onboarding-660.jpg",
    srcset:
      "./assets/screenshots/optimized/onboarding-660.jpg 660w, ./assets/screenshots/optimized/onboarding-990.jpg 990w",
    alt: "MindSense onboarding screen",
    title: "Activation in under 45 seconds",
    description: "Required activation path focuses baseline start and first check-in.",
    bullets: [
      "Step model: baseline then first check-in.",
      "Escalation guidance appears on high values.",
      "Optional permissions can be handled later."
    ]
  },
  today: {
    kicker: "Today",
    image: "./assets/screenshots/optimized/today-660.jpg",
    srcset: "./assets/screenshots/optimized/today-660.jpg 660w, ./assets/screenshots/optimized/today-990.jpg 990w",
    alt: "MindSense today screen",
    title: "State and one next action",
    description: "Today keeps one recommendation dominant with confidence and context available.",
    bullets: [
      "Load, Readiness, Consistency cards with deltas.",
      "Best-next-step recommendation card.",
      "Timeline, drivers, and quick check-in support."
    ]
  },
  regulate: {
    kicker: "Regulate",
    image: "./assets/screenshots/optimized/regulate_run-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_run-660.jpg 660w, ./assets/screenshots/optimized/regulate_run-990.jpg 990w",
    alt: "MindSense regulate screen",
    title: "Guided intervention execution",
    description: "Three-step flow: select protocol, run timer, record impact.",
    bullets: [
      "Ranked presets by scenario and intent.",
      "Focused timer run with minimal distraction.",
      "Outcome capture updates state and history."
    ]
  },
  data: {
    kicker: "Data",
    image: "./assets/screenshots/optimized/data_trends-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_trends-660.jpg 660w, ./assets/screenshots/optimized/data_trends-990.jpg 990w",
    alt: "MindSense data screen",
    title: "Patterns and experiments",
    description: "Trends, overlays, and experiments turn behavior into learning.",
    bullets: [
      "Time windows with smoothing and filters.",
      "Event overlays for contextual pattern reading.",
      "Experiment lifecycle with completion summary."
    ]
  },
  settings: {
    kicker: "Settings",
    image: "./assets/screenshots/optimized/settings-660.jpg",
    srcset:
      "./assets/screenshots/optimized/settings-660.jpg 660w, ./assets/screenshots/optimized/settings-990.jpg 990w",
    alt: "MindSense settings screen",
    title: "Privacy, notifications, and safety controls",
    description: "Settings centralizes operational preferences and trust controls.",
    bullets: [
      "Privacy and data pathways.",
      "Notification, quiet-hours, and motion controls.",
      "Safety and account actions."
    ]
  }
};

const surfaceTabs = Array.from(document.querySelectorAll(".surface-tab"));
const surfaceImage = document.getElementById("surface-image");
const surfaceKicker = document.getElementById("surface-kicker");
const surfaceTitle = document.getElementById("surface-title");
const surfaceDescription = document.getElementById("surface-description");
const surfaceBullets = document.getElementById("surface-bullets");
const surfacePanel = document.getElementById("surface-panel");

const renderSurface = (key) => {
  const payload = surfaceData[key];
  if (!payload || !surfaceImage || !surfaceKicker || !surfaceTitle || !surfaceDescription || !surfaceBullets) {
    return;
  }

  surfaceImage.src = payload.image;
  surfaceImage.srcset = payload.srcset;
  surfaceImage.alt = payload.alt;
  surfaceKicker.textContent = payload.kicker;
  surfaceTitle.textContent = payload.title;
  surfaceDescription.textContent = payload.description;

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
  if (prefersReducedMotion || !window.gsap) {
    node.textContent = String(max);
    return;
  }

  const tracker = { value: 0 };
  window.gsap.to(tracker, {
    value: max,
    duration: 1.05,
    ease: "power2.out",
    onUpdate: () => {
      node.textContent = String(Math.round(tracker.value));
    }
  });
};

if ("IntersectionObserver" in window) {
  const counterObserver = new IntersectionObserver(
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

  metrics.forEach((metric) => counterObserver.observe(metric));
} else {
  setMetricFinalValues();
}

const revealNodes = document.querySelectorAll(".reveal");

if (prefersReducedMotion || !window.gsap || !window.ScrollTrigger) {
  revealNodes.forEach((node) => {
    node.style.opacity = "1";
    node.style.transform = "translateY(0)";
  });
} else {
  window.gsap.registerPlugin(window.ScrollTrigger);

  window.gsap.to(".hero-phone", {
    y: -8,
    duration: 3.6,
    ease: "sine.inOut",
    repeat: -1,
    yoyo: true
  });

  window.gsap.utils.toArray(".reveal").forEach((element) => {
    window.gsap.fromTo(
      element,
      { opacity: 0, y: 20 },
      {
        opacity: 1,
        y: 0,
        duration: 0.72,
        ease: "power2.out",
        scrollTrigger: {
          trigger: element,
          start: "top 86%"
        }
      }
    );
  });
}

const yearNode = document.getElementById("copyright");
if (yearNode) {
  yearNode.textContent = `\u00a9 ${new Date().getFullYear()} MindSense AI`;
}
