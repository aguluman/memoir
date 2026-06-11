// Main JavaScript file for memoir website
(function () {
  "use strict";

  /**
   * Mobile navigation: open/close state, click-outside and Escape to close.
   * Active link state is rendered server-side by the OCaml templates.
   */
  function initNavigation() {
    const mobileToggle = document.querySelector(".mobile-nav-toggle");
    const navList = document.querySelector("#primary-navigation");

    if (!mobileToggle || !navList) return;

    function closeNav() {
      mobileToggle.setAttribute("aria-expanded", "false");
      navList.setAttribute("data-visible", "false");
      document.body.classList.remove("nav-open");
    }

    mobileToggle.addEventListener("click", function () {
      const isVisible = navList.getAttribute("data-visible") === "true";

      mobileToggle.setAttribute("aria-expanded", !isVisible);
      navList.setAttribute("data-visible", !isVisible);

      // Prevent body scrolling while the menu is open
      document.body.classList.toggle("nav-open", !isVisible);
    });

    // Close mobile navigation when clicking on nav links
    navList.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", closeNav);
    });

    // Close mobile navigation when clicking outside
    document.addEventListener("click", function (e) {
      if (
        navList.getAttribute("data-visible") === "true" &&
        !e.target.closest(".nav-list") &&
        !e.target.closest(".mobile-nav-toggle")
      ) {
        closeNav();
      }
    });

    // Handle escape key to close mobile navigation
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && navList.getAttribute("data-visible") === "true") {
        closeNav();
      }
    });
  }

  function initWebsite() {
    initNavigation();

    if (window.hljs) {
      hljs.highlightAll();
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initWebsite);
  } else {
    initWebsite();
  }
})();
