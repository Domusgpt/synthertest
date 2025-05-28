// Polyfill for missing console functions that might be causing errors
(function() {
    // Check if openMCPConsole exists, if not create a stub
    if (typeof window.openMCPConsole === 'undefined') {
        window.openMCPConsole = function() {
            console.log('openMCPConsole stub called');
        };
    }
    
    // Handle Portal Transitions error
    if (typeof window.PortalTransitions === 'undefined') {
        window.PortalTransitions = {
            init: function() {
                console.log('Portal Transitions stub initialized');
            }
        };
    }
    
    // Prevent errors from missing functions
    const missingFunctions = [
        'openMCPConsole',
        'closeMCPConsole',
        'toggleMCPConsole'
    ];
    
    missingFunctions.forEach(funcName => {
        if (typeof window[funcName] === 'undefined') {
            window[funcName] = function() {
                console.log(`${funcName} stub called`);
            };
        }
    });
    
    console.log('Console polyfill loaded');
})();