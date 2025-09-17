# 🚫 PlayStoreSelfUpdateBlocker (PUSBlocker)

Prevents the **Google Play Store** from auto-updating itself. Useful for users trying to maintain valid device attestation under the newer **Play Integrity API** rules.

> ⚠️ Disclaimer: Educational/experimental use only. Use at your own risk. You are responsible for complying with local laws and app policies.

## Details
- **Module ID:** PUSBlocker
- **Version:** 1.0 (versionCode 1.1)
- **Author:** @himanjjp
- **Requires:** Root + Magisk, APatch, or KernelSU

## What it does
- Blocks Play Store **self-update** (does not affect app updates you choose).
- Designed to keep a stable Play Store version on rooted setups.

## Install
- Download the module ZIP from Releases.
- Disconnect your internet connection and uninstall Play Store updates (to revert to the factory version).
- Flash via Magisk Manager, APatch, or KernelSU.
- Reboot your device.

## Uninstall / Restore
- Remove via your root manager (Magisk, APatch, KernelSU) or flash the uninstall ZIP.

## Compatibility
- **Root Solutions:** Magisk 24+, APatch, KernelSU
- **Android:** 10+ (report issues if you find any)
- **Devices:** All Android devices with supported root methods

## Known Issues & Fixes
- ✅ **Fixed:** Module description not showing after installation (corrected `module.prop` format)
- ✅ **Fixed:** System freezes and random reboots (optimized daemon with proper resource management)
- ✅ **Improved:** Reduced CPU usage by 97% (changed from 10-second to 5-minute monitoring intervals)
- ✅ **Enhanced:** Added timeout protection and error handling to prevent system hanging
- ✅ **Added:** Proper process cleanup in uninstall script

## Troubleshooting
- **System freezes:** Update to latest version (v1.0+) - previous versions had resource management issues
- **Description not showing:** Ensure you're using v1.0+ with corrected module.prop format
- **High CPU usage:** Older versions polled too frequently - latest version uses efficient 5-minute intervals

## Changelog
### v1.0 (versionCode 1.1)
- **Fixed:** System stability issues causing freezes and reboots
- **Fixed:** Module description not displaying in root manager
- **Improved:** Daemon efficiency with longer monitoring intervals (5 minutes vs 10 seconds)
- **Added:** Timeout protection for all system commands
- **Added:** PID management to prevent multiple daemon instances
- **Enhanced:** Better error handling and recovery mechanisms
- **Improved:** Proper cleanup in uninstall script

### v1.0 (Initial)
- Initial release with basic Play Store update blocking

## License
MIT (see [LICENSE](./LICENSE)).
