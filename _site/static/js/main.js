// Main JavaScript file for memoir website
(function() {
  'use strict';

  /**
   * Initialize navigation functionality
   */
  function initNavigation() {
    // Mobile navigation toggle (from header.ml)
    const navToggle = document.querySelector('.nav-toggle');
    const primaryNav = document.querySelector('.primary-navigation');
    
    if (navToggle && primaryNav) {
      navToggle.addEventListener('click', function() {
        const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
        
        navToggle.setAttribute('aria-expanded', !isExpanded);
        primaryNav.setAttribute('data-visible', !isExpanded);
      });
    }

    // Mobile navigation toggle (from navigation.ml)
    const mobileToggle = document.querySelector('.mobile-nav-toggle');
    const navList = document.querySelector('#primary-navigation');
    
    if (mobileToggle && navList) {
      mobileToggle.addEventListener('click', function() {
        const isVisible = navList.getAttribute('data-visible') === 'true';
        
        mobileToggle.setAttribute('aria-expanded', !isVisible);
        navList.setAttribute('data-visible', !isVisible);
      });
    }

    // Dropdown menu functionality
    const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
    
    dropdownToggles.forEach(toggle => {
      toggle.addEventListener('click', function(e) {
        e.preventDefault();
        const isExpanded = toggle.getAttribute('aria-expanded') === 'true';
        
        // Close all other dropdowns
        dropdownToggles.forEach(otherToggle => {
          if (otherToggle !== toggle) {
            otherToggle.setAttribute('aria-expanded', 'false');
          }
        });
        
        // Toggle current dropdown
        toggle.setAttribute('aria-expanded', !isExpanded);
      });
    });

    // Close dropdowns when clicking outside
    document.addEventListener('click', function(e) {
      if (!e.target.closest('.has-dropdown')) {
        dropdownToggles.forEach(toggle => {
          toggle.setAttribute('aria-expanded', 'false');
        });
      }
    });

    // Close mobile navigation when clicking on nav links
    const navLinks = document.querySelectorAll('.nav-links a, .dropdown-menu a');
    navLinks.forEach(link => {
      link.addEventListener('click', function() {
        if (navToggle && primaryNav) {
          navToggle.setAttribute('aria-expanded', 'false');
          primaryNav.setAttribute('data-visible', 'false');
        }
        if (mobileToggle && navList) {
          mobileToggle.setAttribute('aria-expanded', 'false');
          navList.setAttribute('data-visible', 'false');
        }
      });
    });
  }

  /**
   * Initialize the website functionality
   */
  function initWebsite() {
    console.log('Memoir website initialized');
    
    // Initialize navigation
    initNavigation();
    
    // Add any additional initialization code here
    // This file is included before theme-toggle.js
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initWebsite);
  } else {
    initWebsite();
  }
})();
