/* --------------------------------------------------------------------------
   PAHATID SYSTEM — Common Utilities
   Version: 1.0 | Last Updated: 2026-09-29
   Shared across ALL pages — Auth, Storage, Formatting, Validation, Notifications
-------------------------------------------------------------------------- */

// ========== STORAGE HELPER ==========
const PahatidStore = {
  get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(`pahatid_${key}`);
      return item ? JSON.parse(item) : defaultValue;
    } catch { return defaultValue; }
  },
  set(key, value) {
    try {
      localStorage.setItem(`pahatid_${key}`, JSON.stringify(value));
      return true;
    } catch { return false; }
  },
  remove(key) {
    localStorage.removeItem(`pahatid_${key}`);
  },
  clearAll() {
    Object.keys(localStorage)
      .filter(k => k.startsWith('pahatid_'))
      .forEach(k => localStorage.removeItem(k));
  }
};

// ========== AUTHENTICATION ==========
const PahatidAuth = {
  isLoggedIn() {
    return !!PahatidStore.get('user_role');
  },
  getRole() {
    return PahatidStore.get('user_role');
  },
  getId() {
    return PahatidStore.get('user_id', '');
  },
  logout(redirectTo = '../index.html') {
    PahatidStore.clearAll();
    window.location.href = redirectTo;
  },
  requireRole(allowedRoles) {
    const role = this.getRole();
    if (!role || !allowedRoles.includes(role)) {
      this.logout();
      return false;
    }
    return true;
  }
};

// ========== FORMATING ==========
const PahatidFormat = {
  currency(amount) {
    return new Intl.NumberFormat('fil-PH', {
      style: 'currency',
      currency: 'PHP',
      minimumFractionDigits: 2
    }).format(amount || 0);
  },
  dateShort(isoString) {
    if (!isoString) return '';
    const d = new Date(isoString);
    return d.toLocaleDateString('fil-PH', {
      month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
    });
  },
  number(num, decimals = 2) {
    return Number(num || 0).toFixed(decimals);
  }
};

// ========== VALIDATION ==========
const PahatidValid = {
  text(value, maxLen = 255, minLen = 1) {
    if (typeof value !== 'string') return false;
    const trimmed = value.trim();
    return trimmed.length >= minLen && trimmed.length <= maxLen;
  },
  number(value, min = null, max = null) {
    const num = parseFloat(value);
    if (isNaN(num)) return false;
    if (min !== null && num < min) return false;
    if (max !== null && num > max) return false;
    return true;
  }
};

// ========== NOTIFICATIONS ==========
const PahatidNotify = {
  show(message, type = 'info', duration = 3000) {
    const existing = document.querySelector('.pahatid-notification');
    if (existing) existing.remove();

    const colors = {
      success: '#10b981',
      error: '#ef4444',
      warn: '#f59e0b',
      info: '#3b82f6'
    };

    const toast = document.createElement('div');
    toast.className = 'pahatid-notification';
    toast.style.cssText = `
      position: fixed; top: 20px; right: 20px; z-index: 9999;
      background: ${colors[type]}; color: white; padding: 12px 24px;
      border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      font-weight: 500; max-width: 320px;
      animation: slideIn 0.3s ease;
    `;
    toast.textContent = message;
    document.body.appendChild(toast);

    setTimeout(() => {
      toast.style.animation = 'slideOut 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, duration);
  },
  success(m) { this.show(m, 'success'); },
  error(m) { this.show(m, 'error'); },
  warn(m) { this.show(m, 'warn'); },
  info(m) { this.show(m, 'info'); }
};

// ========== GLOBAL NAV SETUP ==========
document.addEventListener('DOMContentLoaded', () => {
  // Mobile Nav Toggle
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.getElementById('navLinks');
  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navLinks.classList.toggle('open');
    });
  }

  // Sidebar Toggle
  const sidebar = document.getElementById('sidebar');
  const sidebarToggle = document.getElementById('sidebarToggle');
  const sidebarOverlay = document.getElementById('sidebarOverlay');
  
  const toggleSidebar = (open) => {
    if (!sidebar) return;
    sidebar.classList.toggle('expanded', open);
    if (sidebarOverlay) sidebarOverlay.style.display = open ? 'block' : 'none';
  };

  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', () => toggleSidebar(!sidebar.classList.contains('expanded')));
  }
  if (sidebarOverlay) {
    sidebarOverlay.addEventListener('click', () => toggleSidebar(false));
  }

  // Sidebar Links — Active State
  document.querySelectorAll('.sidebar-link').forEach(link => {
    link.addEventListener('click', function(e) {
      const href = this.getAttribute('href');
      if (href && href.startsWith('#')) {
        document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
        this.classList.add('active');
        toggleSidebar(false);
      }
    });
  });
});

// ========== GLOBAL ANIMATIONS ==========
const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn {
    from { transform: translateX(100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
  @keyframes slideOut {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(100%); opacity: 0; }
  }
`;
document.head.appendChild(style);

console.log('%c PAHATID SYSTEM ', 'background:#f97316; color:white; padding:4px 8px; border-radius:4px; font-weight:bold;');
console.log('Habal-Habal Transport Platform — Ready ✅');
