// -----------------------------------------------------------------------------
// PAHATID SYSTEM — Habal-Habal Transport Services Platform
// FILE: common.js
// TYPE: Shared Core JavaScript
// VERSION: 1.2.0
// LAST UPDATED: 2026-09-28
// STATUS: Active — Ready for Implementation
// DEPLOYMENT: GitHub Pages Compatible — Vanilla JS Only
// SECURITY: No credentials exposed | Input-safe utilities included
// ENHANCEMENTS: Added Collapsible Sidebar / Side Menu System
// -----------------------------------------------------------------------------
//  PURPOSE:
//  Reusable functions & initializers — navigation, sidebar, scroll, validation,
//  formatters, storage, auth, feedback, and shared helpers across all portals
// -----------------------------------------------------------------------------

// =============================================
// TABLE OF CONTENTS
//  1. DOM Ready Initialization
//  2. Top Mobile Navigation Toggle
//  3. Sidebar / Side Menu System — NEW ✅
//  4. Smooth Scroll & Active Link
//  5. Formatters
//  6. Validation & Sanitization
//  7. Local Storage Helpers
//  8. Session & Auth Helpers
//  9. Feedback & Rating Rendering
//  10. Notifications
//  11. Debounce & Performance
// =============================================

(function () {
  'use strict';

  // =============================================
  // 1. INITIALIZE ON DOM READY
  // =============================================
  document.addEventListener('DOMContentLoaded', initCommon, false);

  function initCommon() {
    initTopNavigation();
    initSidebar(); // ✅ Sidebar init
    initSmoothScroll();
    setActiveNavLink();
    observeScrollNavbar();
    console.log('%c🛵 PAHATID SYSTEM — Loaded v1.2', 'color: #2563eb; font-weight: bold; font-size: 14px;');
  }

  // =============================================
  // 2. TOP NAVIGATION (existing mobile menu)
  // =============================================
  function initTopNavigation() {
    const toggle = document.getElementById('navToggle');
    const links = document.getElementById('navLinks');
    if (!toggle || !links) return;

    toggle.addEventListener('click', () => {
      links.classList.toggle('active');
      toggle.setAttribute('aria-expanded', links.classList.contains('active'));
    });

    links.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        if (window.innerWidth < 768) links.classList.remove('active');
      });
    });

    document.addEventListener('click', (e) => {
      if (!toggle.contains(e.target) && !links.contains(e.target)) {
        links.classList.remove('active');
        toggle.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // =============================================
  // 3. SIDEBAR / SIDE MENU — ✅ NEW
  // =============================================
  const SIDEBAR_COLLAPSED_WIDTH = '64px';
  const SIDEBAR_EXPANDED_WIDTH = '260px';

  function initSidebar() {
    const toggleBtn = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    const mainContent = document.getElementById('mainContent');

    if (!sidebar) return; // Skip if no sidebar on page

    // Restore saved state
    const savedState = localStorage.getItem('pahatid_sidebar_state');
    const isMobile = window.innerWidth < 768;
    
    if (!isMobile && savedState === 'expanded') {
      sidebar.classList.add('expanded');
      applySidebarState(true);
    }

    // Toggle button
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        const willExpand = !sidebar.classList.contains('expanded');
        sidebar.classList.toggle('expanded');
        applySidebarState(willExpand);
        
        // Save state only on desktop
        if (window.innerWidth >= 768) {
          localStorage.setItem('pahatid_sidebar_state', willExpand ? 'expanded' : 'collapsed');
        }
      });
    }

    // Mobile overlay close
    if (overlay) {
      overlay.addEventListener('click', () => closeSidebar(sidebar, overlay, mainContent));
    }

    // Sidebar links — close on mobile after click
    sidebar.querySelectorAll('.sidebar-link').forEach(link => {
      link.addEventListener('click', () => {
        if (window.innerWidth < 768) {
          closeSidebar(sidebar, overlay, mainContent);
        }
      });
    });

    // Handle resize
    window.addEventListener('resize', PahatidUtil.debounce(() => {
      if (window.innerWidth < 768) {
        sidebar.classList.remove('expanded');
        applySidebarState(false);
      }
    }, 200));
  }

  function applySidebarState(isExpanded) {
    const sidebar = document.getElementById('sidebar');
    const mainContent = document.getElementById('mainContent');
    const overlay = document.getElementById('sidebarOverlay');
    if (!sidebar) return;

    if (isExpanded) {
      sidebar.style.width = SIDEBAR_EXPANDED_WIDTH;
      if (mainContent) mainContent.style.marginLeft = SIDEBAR_EXPANDED_WIDTH;
      if (overlay && window.innerWidth < 768) overlay.style.opacity = '1';
      if (overlay && window.innerWidth < 768) overlay.style.pointerEvents = 'auto';
    } else {
      sidebar.style.width = SIDEBAR_COLLAPSED_WIDTH;
      if (mainContent) mainContent.style.marginLeft = SIDEBAR_COLLAPSED_WIDTH;
      if (overlay) overlay.style.opacity = '0';
      if (overlay) overlay.style.pointerEvents = 'none';
    }
  }

  function closeSidebar(sidebar, overlay, mainContent) {
    if (!sidebar) return;
    sidebar.classList.remove('expanded');
    applySidebarState(false);
  }

  // =============================================
  // 4. SMOOTH SCROLL & ACTIVE LINK
  // =============================================
  function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function (e) {
        const targetId = this.getAttribute('href');
        if (targetId === '#') return;
        const targetEl = document.querySelector(targetId);
        if (!targetEl) return;
        e.preventDefault();
        const navHeight = document.querySelector('.navbar')?.offsetHeight || 80;
        const sidebar = document.getElementById('sidebar');
        const offset = sidebar && window.innerWidth >= 768 ? 20 : navHeight + 20;
        window.scrollTo({
          top: targetEl.offsetTop - offset,
          behavior: 'smooth'
        });
      });
    });
  }

  function setActiveNavLink() {
    const sections = document.querySelectorAll('section[id]');
    if (!sections.length) return;

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          // Top nav
          document.querySelectorAll('.nav-links a[href^="#"]').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${entry.target.id}`) {
              link.classList.add('active');
            }
          });
          // Sidebar
          document.querySelectorAll('.sidebar-link[href^="#"]').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${entry.target.id}`) {
              link.classList.add('active');
            }
          });
        }
      });
    }, { threshold: 0.3, rootMargin: '-80px 0px 0px 0px' });

    sections.forEach(section => observer.observe(section));
  }

  function observeScrollNavbar() {
    const navbar = document.querySelector('.navbar');
    if (!navbar) return;
    window.addEventListener('scroll', () => {
      navbar.style.boxShadow = window.scrollY > 50
        ? '0 2px 10px rgba(0,0,0,0.1)'
        : '0 1px 2px rgba(0,0,0,0.05)';
    }, { passive: true });
  }

  // =============================================
  // 5. FORMATTERS — Consistent Display Across Site
  // =============================================
  window.PahatidFormat = {
    currency: function (amount, decimals = 2) {
      const num = parseFloat(amount) || 0;
      return new Intl.NumberFormat('ph-PH', {
        style: 'currency', currency: 'PHP', minimumFractionDigits: decimals
      }).format(num);
    },
    distance: km => `${(parseFloat(km) || 0).toFixed(2)} km`,
    time: d => d ? new Date(d).toLocaleString('ph-PH', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '',
    dateShort: d => d ? new Date(d).toLocaleDateString('ph-PH') : '',
    ratingStars: function (value, max = 5) {
      const num = Math.max(0, Math.min(max, parseFloat(value) || 0));
      return '⭐'.repeat(Math.floor(num)) + (num % 1 >= 0.25 ? '½' : '') + '☆'.repeat(Math.ceil(max - num));
    },
    maskCard: (lastFour, net) => net ? `${net} •••• ${lastFour}` : `•••• ${lastFour}`
  };

  // =============================================
  // 6. VALIDATION & SANITIZATION
  // =============================================
  window.PahatidValid = {
    text: (s, max = 255) => typeof s === 'string' && s.trim().length > 0 && s.trim().length <= max,
    phone: n => typeof n === 'string' && /^(09|\+639)\d{9}$/.test(n.replace(/\D/g, '')),
    email: a => typeof a === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(a),
    coords: (lat, lng) => isFinite(lat) && Math.abs(lat) <= 90 && isFinite(lng) && Math.abs(lng) <= 180,
    fare: v => !isNaN(parseFloat(v)) && parseFloat(v) >= 0 && parseFloat(v) <= 99999,
    sanitizeHTML: str => { const t = document.createElement('div'); t.textContent = str; return t.innerHTML; },
    escape: function(s) { return this.sanitizeHTML(s); }
  };

  // =============================================
  // 7. LOCAL STORAGE
  // =============================================
  const PREFIX = 'pahatid_';
  const ALLOWED_KEYS = ['user_role', 'user_id', 'theme', 'lang', 'last_ride', 'sidebar_state'];
  window.PahatidStore = {
    set: (k, v) => ALLOWED_KEYS.includes(k) && (localStorage.setItem(PREFIX + k, JSON.stringify(v)), true),
    get: (k, def = null) => ALLOWED_KEYS.includes(k) ? JSON.parse(localStorage.getItem(PREFIX + k)) ?? def : def,
    remove: k => localStorage.removeItem(PREFIX + k),
    clearAll: () => ALLOWED_KEYS.forEach(k => localStorage.removeItem(PREFIX + k))
  };

  // =============================================
  // 8. AUTH HELPERS
  // =============================================
  window.PahatidAuth = {
    getRole: () => PahatidStore.get('user_role'),
    getUserId: () => PahatidStore.get('user_id'),
    isLoggedIn: function() { return !!this.getRole() && !!this.getUserId(); },
    requireRole: function(roles, redir) {
      const ok = roles.includes(this.getRole());
      !ok && redir && (window.location.href = redir);
      return ok;
    },
    logout: (redir = '/index.html') => (PahatidStore.clearAll(), window.location.href = redir)
  };

  // =============================================
  // 9. FEEDBACK RENDERING
  // =============================================
  window.PahatidUI = {
    renderFeedbackCards: function(id, arr) {
      const c = document.getElementById(id);
      if (!c || !Array.isArray(arr)) return;
      c.innerHTML = '';
      arr.forEach(fb => {
        c.innerHTML += `
          <div class="feedback-card">
            <div class="feedback-header">
              <span class="feedback-author">${PahatidValid.sanitizeHTML(fb.author || 'Gumagamit')}</span>
              <span class="feedback-rating">${PahatidFormat.ratingStars(fb.rating)}</span>
            </div>
            <p class="feedback-text">${PahatidValid.sanitizeHTML(fb.text)}</p>
            <span class="feedback-date">${fb.date ? PahatidFormat.dateShort(fb.date) : ''} • ${fb.type || ''}</span>
          </div>`;
      });
    }
  };

  // =============================================
  // 10. NOTIFICATIONS
  // =============================================
  window.PahatidNotify = {
    show: function(msg, type = 'info', dur = 4000) {
      const colors = { success:'#10b981', error:'#ef4444', warning:'#f59e0b', info:'#2563eb' };
      const box = Object.assign(document.createElement('div'), {
        style: `position:fixed;top:90px;right:20px;z-index:9999;background:${colors[type]};color:#fff;padding:1rem 1.5rem;border-radius:0.5rem;box-shadow:0 10px 25px rgba(0,0,0,0.2);max-width:320px;`
      });
      box.textContent = msg;
      document.body.appendChild(box);
      setTimeout(() => { box.style.opacity = '0'; setTimeout(() => box.remove(), 300); }, dur);
    },
    success: m => this.show(m, 'success'),
    error: m => this.show(m, 'error'),
    warn: m => this.show(m, 'warning')
  };

  // =============================================
  // 11. DEBOUNCE & HELPERS
  // =============================================
  window.PahatidUtil = {
    debounce: function(fn, ms = 300) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; },
    getQueryParam: n => new URLSearchParams(window.location.search).get(n)
  };

})();

// -----------------------------------------------------------------------------
// END OF FILE: common.js
// REQUIRED CSS UPDATES IN main.css BELOW 👇
// -----------------------------------------------------------------------------
