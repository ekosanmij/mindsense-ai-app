const navToggle = document.querySelector(".nav-toggle");
const nav = document.querySelector(".site-nav");

if (navToggle && nav) {
  navToggle.addEventListener("click", () => {
    nav.classList.toggle("is-open");
  });
}

const surfaceData = {
  today: {
    image: "./assets/screenshots/today.png",
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
    image: "./assets/screenshots/regulate_select.png",
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
    image: "./assets/screenshots/data_trends.png",
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
    image: "./assets/screenshots/settings.png",
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
    image: "./assets/screenshots/onboarding.png",
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

const tabs = document.querySelectorAll(".surface-tab");
const surfaceImage = document.getElementById("surface-image");
const surfaceTitle = document.getElementById("surface-title");
const surfaceCopy = document.getElementById("surface-copy");
const surfaceBullets = document.getElementById("surface-bullets");

const renderSurface = (key) => {
  const payload = surfaceData[key];
  if (!payload || !surfaceImage || !surfaceTitle || !surfaceCopy || !surfaceBullets) {
    return;
  }

  surfaceImage.src = payload.image;
  surfaceImage.alt = payload.alt;
  surfaceTitle.textContent = payload.title;
  surfaceCopy.textContent = payload.copy;
  surfaceBullets.innerHTML = payload.bullets.map((item) => `<li>${item}</li>`).join("");
};

renderSurface("today");

tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    tabs.forEach((candidate) => {
      candidate.classList.remove("is-active");
      candidate.setAttribute("aria-selected", "false");
    });

    tab.classList.add("is-active");
    tab.setAttribute("aria-selected", "true");

    const key = tab.getAttribute("data-screen");
    renderSurface(key);
  });
});

const metrics = document.querySelectorAll(".metric[data-count]");

const animateCounter = (node) => {
  const max = Number(node.getAttribute("data-count") || 0);
  const tracker = { value: 0 };

  if (!window.gsap) {
    node.textContent = String(max);
    return;
  }

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
}

if (window.gsap && window.ScrollTrigger) {
  window.gsap.registerPlugin(window.ScrollTrigger);

  window.gsap.to(".phone-card-main", {
    y: -18,
    duration: 2.8,
    ease: "sine.inOut",
    repeat: -1,
    yoyo: true
  });

  window.gsap.to(".phone-card-alt", {
    y: 14,
    duration: 2.6,
    ease: "sine.inOut",
    repeat: -1,
    yoyo: true
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
} else {
  document.querySelectorAll(".reveal").forEach((node) => {
    node.style.opacity = "1";
    node.style.transform = "translateY(0)";
  });
}

const yearNode = document.getElementById("copyright");
if (yearNode) {
  yearNode.textContent = `\u00a9 ${new Date().getFullYear()} MindSense AI`;
}
