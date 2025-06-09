// Main JavaScript file for memoir website
(function() {
  'use strict';

  /**
   * Initialize the website functionality
   */
  function initWebsite() {
    console.log('Memoir website initialized');
    
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
