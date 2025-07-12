// Main JavaScript file for memoir website
(function() {
  'use strict';

  /**
   * Initialize navigation functionality
   */
  function initNavigation() {
    // Mobile navigation toggle
    const mobileToggle = document.querySelector('.mobile-nav-toggle');
    const navList = document.querySelector('#primary-navigation');
    
    if (mobileToggle && navList) {
      mobileToggle.addEventListener('click', function() {
        const isVisible = navList.getAttribute('data-visible') === 'true';
        
        mobileToggle.setAttribute('aria-expanded', !isVisible);
        navList.setAttribute('data-visible', !isVisible);
        
        // Add body class to prevent scrolling when menu is open
        if (!isVisible) {
          document.body.classList.add('nav-open');
        } else {
          document.body.classList.remove('nav-open');
        }
      });
    }

    // Close mobile navigation when clicking on nav links
    const navLinks = document.querySelectorAll('.nav-list a');
    navLinks.forEach(link => {
      link.addEventListener('click', function() {
        if (mobileToggle && navList) {
          mobileToggle.setAttribute('aria-expanded', 'false');
          navList.setAttribute('data-visible', 'false');
          document.body.classList.remove('nav-open');
        }
      });
    });

    // Close mobile navigation when clicking outside
    document.addEventListener('click', function(e) {
      if (navList && navList.getAttribute('data-visible') === 'true') {
        // If clicking outside the navigation and not on the toggle button
        if (!e.target.closest('.nav-list') && !e.target.closest('.mobile-nav-toggle')) {
          mobileToggle.setAttribute('aria-expanded', 'false');
          navList.setAttribute('data-visible', 'false');
          document.body.classList.remove('nav-open');
        }
      }
    });

    // Handle escape key to close mobile navigation
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && navList && navList.getAttribute('data-visible') === 'true') {
        mobileToggle.setAttribute('aria-expanded', 'false');
        navList.setAttribute('data-visible', 'false');
        document.body.classList.remove('nav-open');
      }
    });
    
    // Active navigation state based on current URL
    const currentPath = window.location.pathname;
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
      const link = item.querySelector('a');
      if (link) {
        const href = link.getAttribute('href');
        // Match exact path or if it's the homepage
        if (href === currentPath || 
            (href === '/' && currentPath === '/') ||
            (href !== '/' && currentPath.startsWith(href))) {
          item.classList.add('active');
        }
      }
    });
    
    // Legacy support for old navigation structure
    const navToggle = document.querySelector('.nav-toggle');
    const primaryNav = document.querySelector('.primary-navigation');
    
    if (navToggle && primaryNav) {
      navToggle.addEventListener('click', function() {
        const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
        
        navToggle.setAttribute('aria-expanded', !isExpanded);
        primaryNav.setAttribute('data-visible', !isExpanded);
      });
    }
    
    // Dropdown menu functionality (if present)
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
