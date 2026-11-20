pragma Singleton

import Quickshell

// Prefixed logging: Logger.i("Settings", "loaded", path)
Singleton {
    function d(module, ...args) { console.debug(`[${module}]`, ...args); }
    function i(module, ...args) { console.info(`[${module}]`, ...args); }
    function w(module, ...args) { console.warn(`[${module}]`, ...args); }
    function e(module, ...args) { console.error(`[${module}]`, ...args); }
}
