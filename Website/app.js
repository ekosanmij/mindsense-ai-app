(() => {
  const doc = document;
  const root = doc.documentElement;
  root.classList.remove('no-js');
  root.classList.add('js');

  const reduceMotionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
  const prefersReducedMotion = () => reduceMotionQuery.matches;

  const rafThrottle = (fn) => {
    let ticking = false;
    return (...args) => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        ticking = false;
        fn(...args);
      });
    };
  };

  const initMobileNav = () => {
    const toggle = doc.querySelector('.menu-toggle');
    const nav = doc.querySelector('.site-nav');
    const actions = doc.querySelector('.site-header__actions');
    if (!toggle || !nav || !actions) return;

    const setOpen = (open) => {
      toggle.setAttribute('aria-expanded', String(open));
      toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
      nav.classList.toggle('is-open', open);
      actions.classList.toggle('is-open', open);
    };

    setOpen(false);

    toggle.addEventListener('click', () => {
      const open = toggle.getAttribute('aria-expanded') !== 'true';
      setOpen(open);
    });

    nav.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        if (window.innerWidth <= 1024) setOpen(false);
      });
    });

    window.addEventListener('resize', rafThrottle(() => {
      if (window.innerWidth > 1024) {
        nav.classList.remove('is-open');
        actions.classList.remove('is-open');
        toggle.setAttribute('aria-expanded', 'false');
      }
    }));
  };

  const initScrollChrome = () => {
    const header = doc.querySelector('.site-header');
    const progressBar = doc.getElementById('scroll-progress-bar');
    const backToTop = doc.getElementById('back-to-top');
    if (!header && !progressBar && !backToTop) return;

    const update = () => {
      const y = window.scrollY || window.pageYOffset;
      if (header) header.classList.toggle('is-scrolled', y > 8);

      if (progressBar) {
        const scrollable = Math.max(doc.documentElement.scrollHeight - window.innerHeight, 1);
        const pct = Math.min(100, Math.max(0, (y / scrollable) * 100));
        progressBar.style.width = `${pct}%`;
      }

      if (backToTop) {
        backToTop.hidden = y < 700;
      }
    };

    const onScroll = rafThrottle(update);
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    update();

    if (backToTop) {
      backToTop.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: prefersReducedMotion() ? 'auto' : 'smooth' });
      });
    }
  };

  const initReveal = () => {
    const items = Array.from(doc.querySelectorAll('[data-reveal]'));
    if (!items.length) return;

    if (!('IntersectionObserver' in window) || prefersReducedMotion()) {
      items.forEach((el) => el.classList.add('is-visible'));
      return;
    }

    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        obs.unobserve(entry.target);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });

    items.forEach((el) => observer.observe(el));
  };

  const initCounters = () => {
    const counters = Array.from(doc.querySelectorAll('[data-count-to]'));
    if (!counters.length) return;

    const runCounter = (el) => {
      if (el.dataset.countAnimated === 'true') return;
      el.dataset.countAnimated = 'true';

      const target = Number(el.getAttribute('data-count-to'));
      if (!Number.isFinite(target)) return;

      if (prefersReducedMotion()) {
        el.textContent = new Intl.NumberFormat().format(target);
        return;
      }

      const duration = Math.min(1200, Math.max(500, target < 20 ? 700 : 900));
      const start = performance.now();
      const formatter = new Intl.NumberFormat();

      const tick = (now) => {
        const progress = Math.min(1, (now - start) / duration);
        const eased = 1 - Math.pow(1 - progress, 3);
        const value = Math.round(target * eased);
        el.textContent = formatter.format(value);
        if (progress < 1) requestAnimationFrame(tick);
      };

      requestAnimationFrame(tick);
    };

    if (!('IntersectionObserver' in window)) {
      counters.forEach(runCounter);
      return;
    }

    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        runCounter(entry.target);
        obs.unobserve(entry.target);
      });
    }, { threshold: 0.35 });

    counters.forEach((el) => observer.observe(el));
  };

  const initFAQ = () => {
    const faqButtons = Array.from(doc.querySelectorAll('.faq-item button[aria-controls]'));
    if (!faqButtons.length) return;

    const setState = (button, expanded) => {
      const panelId = button.getAttribute('aria-controls');
      const panel = panelId ? doc.getElementById(panelId) : null;
      button.setAttribute('aria-expanded', String(expanded));
      if (panel) panel.hidden = !expanded;
    };

    faqButtons.forEach((button) => {
      button.addEventListener('click', () => {
        const isExpanded = button.getAttribute('aria-expanded') === 'true';
        faqButtons.forEach((other) => setState(other, false));
        setState(button, !isExpanded);
      });
    });
  };

  const cycleTabFocus = (tabs, currentIndex, direction) => {
    const nextIndex = (currentIndex + direction + tabs.length) % tabs.length;
    tabs[nextIndex].focus();
    return nextIndex;
  };

  const initScreenTabs = () => {
    const tablist = doc.querySelector('.screen-tabs');
    if (!tablist) return;

    const tabs = Array.from(tablist.querySelectorAll('[role="tab"]'));
    const panels = tabs.map((tab) => doc.getElementById(tab.getAttribute('aria-controls'))).filter(Boolean);
    if (!tabs.length) return;

    const activate = (tabToActivate, { focus = false } = {}) => {
      tabs.forEach((tab) => {
        const active = tab === tabToActivate;
        tab.classList.toggle('is-active', active);
        tab.setAttribute('aria-selected', String(active));
        tab.tabIndex = active ? 0 : -1;
        const panelId = tab.getAttribute('aria-controls');
        const panel = panelId ? doc.getElementById(panelId) : null;
        if (panel) {
          panel.hidden = !active;
          panel.classList.toggle('is-active', active);
        }
      });
      if (focus) tabToActivate.focus();
    };

    tabs.forEach((tab) => {
      tab.addEventListener('click', () => activate(tab));
      tab.addEventListener('keydown', (event) => {
        const index = tabs.indexOf(tab);
        if (index < 0) return;
        switch (event.key) {
          case 'ArrowRight':
          case 'ArrowDown': {
            event.preventDefault();
            const i = cycleTabFocus(tabs, index, 1);
            activate(tabs[i]);
            break;
          }
          case 'ArrowLeft':
          case 'ArrowUp': {
            event.preventDefault();
            const i = cycleTabFocus(tabs, index, -1);
            activate(tabs[i]);
            break;
          }
          case 'Home':
            event.preventDefault();
            activate(tabs[0], { focus: true });
            break;
          case 'End':
            event.preventDefault();
            activate(tabs[tabs.length - 1], { focus: true });
            break;
          default:
            break;
        }
      });
    });

    // Defensive sync for initial markup.
    const initial = tabs.find((tab) => tab.getAttribute('aria-selected') === 'true') || tabs[0];
    activate(initial);
  };

  const initHeroTabs = () => {
    const tablist = doc.querySelector('.hero-rail');
    const shots = Array.from(doc.querySelectorAll('.hero-shot[data-hero-shot]'));
    if (!tablist || !shots.length) return;

    const tabs = Array.from(tablist.querySelectorAll('.hero-rail__button[data-hero-target]'));
    if (!tabs.length) return;

    let activeKey = tabs.find((tab) => tab.classList.contains('is-active'))?.dataset.heroTarget || tabs[0].dataset.heroTarget;
    let timer = null;

    const setActive = (key, { focus = false } = {}) => {
      activeKey = key;
      tabs.forEach((tab) => {
        const active = tab.dataset.heroTarget === key;
        tab.classList.toggle('is-active', active);
        tab.setAttribute('aria-selected', String(active));
        tab.tabIndex = active ? 0 : -1;
        if (focus && active) tab.focus();
      });
      shots.forEach((shot) => {
        const active = shot.dataset.heroShot === key;
        shot.classList.toggle('is-active', active);
        shot.setAttribute('aria-hidden', String(!active));
      });
    };

    const restartAuto = () => {
      if (timer) clearInterval(timer);
      if (prefersReducedMotion()) return;
      timer = window.setInterval(() => {
        if (doc.hidden) return;
        const index = tabs.findIndex((tab) => tab.dataset.heroTarget === activeKey);
        const next = tabs[(index + 1) % tabs.length];
        if (next) setActive(next.dataset.heroTarget || tabs[0].dataset.heroTarget);
      }, 4200);
    };

    tabs.forEach((tab) => {
      tab.addEventListener('click', () => {
        setActive(tab.dataset.heroTarget || activeKey);
        restartAuto();
      });

      tab.addEventListener('keydown', (event) => {
        const index = tabs.indexOf(tab);
        if (index < 0) return;
        if (['ArrowRight', 'ArrowDown'].includes(event.key)) {
          event.preventDefault();
          const nextIndex = cycleTabFocus(tabs, index, 1);
          setActive(tabs[nextIndex].dataset.heroTarget || activeKey, { focus: true });
          restartAuto();
        } else if (['ArrowLeft', 'ArrowUp'].includes(event.key)) {
          event.preventDefault();
          const prevIndex = cycleTabFocus(tabs, index, -1);
          setActive(tabs[prevIndex].dataset.heroTarget || activeKey, { focus: true });
          restartAuto();
        } else if (event.key === 'Home') {
          event.preventDefault();
          setActive(tabs[0].dataset.heroTarget || activeKey, { focus: true });
          restartAuto();
        } else if (event.key === 'End') {
          event.preventDefault();
          setActive(tabs[tabs.length - 1].dataset.heroTarget || activeKey, { focus: true });
          restartAuto();
        }
      });
    });

    tablist.addEventListener('mouseenter', () => {
      if (timer) clearInterval(timer);
    });

    tablist.addEventListener('mouseleave', restartAuto);
    tablist.addEventListener('focusin', () => {
      if (timer) clearInterval(timer);
    });
    tablist.addEventListener('focusout', (event) => {
      if (!tablist.contains(event.relatedTarget)) restartAuto();
    });

    setActive(activeKey);
    restartAuto();

    const mediaHandler = () => restartAuto();
    if (typeof reduceMotionQuery.addEventListener === 'function') {
      reduceMotionQuery.addEventListener('change', mediaHandler);
    } else if (typeof reduceMotionQuery.addListener === 'function') {
      reduceMotionQuery.addListener(mediaHandler);
    }
  };

  initMobileNav();
  initScrollChrome();
  initReveal();
  initCounters();
  initFAQ();
  initScreenTabs();
  initHeroTabs();
})();
