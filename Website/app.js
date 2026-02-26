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
      threshold: 0.01
    }
  );

  sectionLinkMap.forEach((_, id) => {
    const section = document.getElementById(id);
    if (section) {
      sectionObserver.observe(section);
    }
  });
}

const surfaceData = {
  today: {
    image: "./assets/screenshots/optimized/today-660.jpg",
    srcset:
      "./assets/screenshots/optimized/today-660.jpg 660w, ./assets/screenshots/optimized/today-990.jpg 990w",
    alt: "MindSense Today screen",
    title: "Today: state + one action",
    copy: "The command deck keeps one primary path visible while preserving confidence details, drivers, and timeline context.",
    bullets: [
      "Load, Readiness, and Consistency with daily delta context.",
      "Single best-next-step recommendation with rationale.",
      "Timeline episodes with attribution and rapid context labels."
    ]
  },
  regulate: {
    image: "./assets/screenshots/optimized/regulate_select-660.jpg",
    srcset:
      "./assets/screenshots/optimized/regulate_select-660.jpg 660w, ./assets/screenshots/optimized/regulate_select-990.jpg 990w",
    alt: "MindSense Regulate protocol selection screen",
    title: "Regulate: protocol execution",
    copy: "Three-step flow (Select, Run, Record) keeps intervention sessions short, measurable, and repeatable.",
    bullets: [
      "Intent-aware ranked protocol presets.",
      "Timer guidance and post-session impact capture.",
      "Outcome signals feed deterministic recommendation updates."
    ]
  },
  data: {
    image: "./assets/screenshots/optimized/data_trends-660.jpg",
    srcset:
      "./assets/screenshots/optimized/data_trends-660.jpg 660w, ./assets/screenshots/optimized/data_trends-990.jpg 990w",
    alt: "MindSense Data trends screen",
    title: "Data: trends, experiments, and history",
    copy: "Data workspaces translate behavior into pattern insight and operational next actions.",
    bullets: [
      "Trend explorer with filters and event overlays.",
      "Focused 7-day experiments with completion summaries.",
      "History stream for session, check-in, and experiment events."
    ]
  },
  settings: {
    image: "./assets/screenshots/optimized/settings-660.jpg",
    srcset:
      "./assets/screenshots/optimized/settings-660.jpg 660w, ./assets/screenshots/optimized/settings-990.jpg 990w",
    alt: "MindSense Settings screen",
    title: "Settings: privacy and operational controls",
    copy: "Settings centralizes permissions, safety options, notifications, and accessibility preferences.",
    bullets: [
      "Privacy/data controls and health permission management.",
      "Quiet hours, nudges, and battery-friendly mode switches.",
      "Safety entries including escalation and crisis resources."
    ]
  },
  onboarding: {
    image: "./assets/screenshots/optimized/onboarding-660.jpg",
    srcset:
      "./assets/screenshots/optimized/onboarding-660.jpg 660w, ./assets/screenshots/optimized/onboarding-990.jpg 990w",
    alt: "MindSense onboarding screen",
    title: "Onboarding: under-45-second activation",
    copy: "Activation keeps early setup lightweight: baseline start, first check-in, then full app entry.",
    bullets: [
      "Step model with clear progress framing.",
      "Check-in capture and escalation copy at high load values.",
      "Trust-first entry before main tab workflow."
    ]
  }
};

const tabs = Array.from(document.querySelectorAll(".surface-tab"));
const surfaceImage = document.getElementById("surface-image");
const surfaceTitle = document.getElementById("surface-title");
const surfaceCopy = document.getElementById("surface-copy");
const surfaceBullets = document.getElementById("surface-bullets");
const surfacePanel = document.getElementById("surface-panel");

const renderSurface = (key) => {
  const payload = surfaceData[key];
  if (!payload || !surfaceImage || !surfaceTitle || !surfaceCopy || !surfaceBullets) {
    return;
  }

  surfaceImage.src = payload.image;
  surfaceImage.srcset = payload.srcset;
  surfaceImage.alt = payload.alt;
  surfaceTitle.textContent = payload.title;
  surfaceCopy.textContent = payload.copy;

  const bulletNodes = payload.bullets.map((item) => {
    const li = document.createElement("li");
    li.textContent = item;
    return li;
  });
  surfaceBullets.replaceChildren(...bulletNodes);
};

const activateTab = (nextTab, focusTab = true) => {
  if (!nextTab) {
    return;
  }

  tabs.forEach((candidate) => {
    const active = candidate === nextTab;
    candidate.classList.toggle("is-active", active);
    candidate.setAttribute("aria-selected", active ? "true" : "false");
    candidate.setAttribute("tabindex", active ? "0" : "-1");
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

if (tabs.length > 0) {
  const defaultTab = tabs.find((node) => node.classList.contains("is-active")) || tabs[0];
  activateTab(defaultTab, false);

  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => activateTab(tab, false));

    tab.addEventListener("keydown", (event) => {
      const key = event.key;
      if (!["ArrowRight", "ArrowLeft", "Home", "End", "Enter", " "].includes(key)) {
        return;
      }

      event.preventDefault();

      if (key === "Enter" || key === " ") {
        activateTab(tab, false);
        return;
      }

      let targetIndex = index;
      if (key === "ArrowRight") {
        targetIndex = (index + 1) % tabs.length;
      } else if (key === "ArrowLeft") {
        targetIndex = (index - 1 + tabs.length) % tabs.length;
      } else if (key === "Home") {
        targetIndex = 0;
      } else if (key === "End") {
        targetIndex = tabs.length - 1;
      }

      activateTab(tabs[targetIndex]);
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
    duration: 1.2,
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

  window.gsap.to(".phone-card-main", {
    y: -10,
    duration: 3.4,
    ease: "sine.inOut",
    repeat: -1,
    yoyo: true
  });

  window.gsap.to(".phone-card-alt", {
    y: 8,
    duration: 3.2,
    ease: "sine.inOut",
    repeat: -1,
    yoyo: true
  });

  window.gsap.utils.toArray(".reveal").forEach((element) => {
    window.gsap.fromTo(
      element,
      { opacity: 0, y: 22 },
      {
        opacity: 1,
        y: 0,
        duration: 0.75,
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
