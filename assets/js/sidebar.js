// =========================================
// Project: Pahatid System Project
// File: assets/js/sidebar.js
// Description: Global Sidebar Controller (Ensures Identical Behavior Across All Portals)
// Author: AI Assistant
// Date: 2026-09-29
// Version: 1.0.0
// Usage: Include this script in the <head> or before </body> on ALL pages.
// =========================================

document.addEventListener('DOMContentLoaded', () => {
    const sidebar = document.getElementById('app-sidebar');
    const toggleBtn = document.getElementById('sidebarToggleBtn');
    const overlay = document.getElementById('sidebar-overlay');
    
    // Safety check: If elements don't exist (e.g., on login page), skip execution
    if (!sidebar || !toggleBtn) return;

    /**
     * Opens the Sidebar
     */
    function openSidebar() {
        sidebar.classList.add('open');
        if (overlay) overlay.classList.add('active');
        document.body.style.overflow = 'hidden'; // Prevent background scrolling on mobile
    }

    /**
     * Closes the Sidebar
     */
    function closeSidebar() {
        sidebar.classList.remove('open');
        if (overlay) overlay.classList.remove('active');
        document.body.style.overflow = ''; // Restore scrolling
    }

    /**
     * Toggles the Sidebar State
     */
    function toggleSidebar(e) {
        e.stopPropagation(); // Prevent event bubbling
        if (sidebar.classList.contains('open')) {
            closeSidebar();
        } else {
            openSidebar();
        }
    }

    // --- EVENT LISTENERS ---

    // 1. Click on Hamburger Button
    toggleBtn.addEventListener('click', toggleSidebar);

    // 2. Click on Overlay (to close)
    if (overlay) {
        overlay.addEventListener('click', closeSidebar);
    }

    // 3. Close sidebar when clicking a link inside it (Mobile UX improvement)
    const navLinks = sidebar.querySelectorAll('.nav-link-custom');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            // Only auto-close on small screens (< 992px)
            if (window.innerWidth < 992) {
                closeSidebar();
            }
        });
    });

    // 4. Handle Window Resize (Reset state if switching between Mobile/Desktop)
    window.addEventListener('resize', () => {
        if (window.innerWidth >= 992) {
            // On Desktop, ensure sidebar is logically "open" via CSS, 
            // but remove any lingering overlays from mobile state
            closeSidebar(); 
        }
    });
});
