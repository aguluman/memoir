// Theme Toggle Functionality for Dark/Light Mode
(function() {
  'use strict';

  // Apply theme immediately to prevent flicker - this runs before DOM is ready
  (function applyThemeImmediately() {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else if (savedTheme === 'light') {
      document.documentElement.setAttribute('data-theme', 'light');
    }
    // If no saved theme, leave as default (light mode from CSS)
  })();

  /**
   * Initialize theme toggle functionality
   */
  function initThemeToggle() {
    // Check for saved theme preference or default to light mode
    const savedTheme = localStorage.getItem('theme');
    const defaultTheme = savedTheme || 'light'; // Default to light, no system preference check

    // Apply the initial theme (this will update icons and ensure consistency)
    setTheme(defaultTheme);
    
    // Set up theme toggle button
    const themeToggle = document.querySelector('.theme-toggle');
    if (themeToggle) {
      themeToggle.addEventListener('click', toggleTheme);
      
      // Add keyboard support for accessibility
      themeToggle.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          toggleTheme();
        }
      });
    }
    
    // Listen for system theme changes (optional - only if no manual preference is set)
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
      // Only auto-switch if user hasn't manually set a preference
      if (!localStorage.getItem('theme')) {
        setTheme(e.matches ? 'dark' : 'light');
      }
    });
  }

  /**
   * Set the theme
   * @param {string} theme - 'light' or 'dark'
   */
  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    updateThemeToggleIcon(theme);
  }

  /**
   * Toggle between light and dark themes
   */
  function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
    
    // Optional: Add a brief animation feedback
    const themeToggle = document.querySelector('.theme-toggle');
    if (themeToggle) {
      themeToggle.style.transform = 'scale(0.9)';
      setTimeout(() => {
        themeToggle.style.transform = '';
      }, 150);
    }
  }

  /**
   * Update the theme toggle button icon
   * @param {string} theme - 'light' or 'dark'
   */
  function updateThemeToggleIcon(theme) {
    const sunIcon = document.querySelector('.theme-toggle .sun-icon');
    const moonIcon = document.querySelector('.theme-toggle .moon-icon');
    
    if (sunIcon && moonIcon) {
      if (theme === 'dark') {
        sunIcon.style.display = 'block';
        moonIcon.style.display = 'none';
      } else {
        sunIcon.style.display = 'none';
        moonIcon.style.display = 'block';
      }
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initThemeToggle);
  } else {
    initThemeToggle();
  }

  // Export for potential use in other scripts
  window.ThemeToggle = {
    setTheme: setTheme,
    toggleTheme: toggleTheme
  };
})();
