// Theme toggle: flips data-theme and persists the choice.
// All presentation (colors, icons, color-scheme) is CSS, keyed on [data-theme].
// The inline <head> script applies the saved/system theme before first paint.
(function () {
  "use strict";

  const toggle = document.querySelector(".theme-toggle");
  if (!toggle) return;

  toggle.addEventListener("click", function () {
    const next =
      document.documentElement.getAttribute("data-theme") === "dark"
        ? "light"
        : "dark";
    document.documentElement.setAttribute("data-theme", next);
    document.documentElement.style.colorScheme = next;
    localStorage.setItem("theme", next);
  });
})();
