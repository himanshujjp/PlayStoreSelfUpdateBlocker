# 🚫 PlayStoreSelfUpdateBlocker (PUSBlocker)

Prevents the **Google Play Store** from auto-updating itself. Useful for users trying to maintain valid device attestation under the newer **Play Integrity API** rules.

> ⚠️ Disclaimer: Educational/experimental use only. Use at your own risk. You are responsible for complying with local laws and app policies.

## Details
- **Module ID:** PUSBlocker
- **Version:** 1.0 (versionCode 1)
- **Author:** @himanjjp
- **Requires:** Root + Magisk (or compatible)

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
- Android 10+ (report issues if you find any)
- Magisk 24+

## Changelog
### v1.0
- Initial release.

## License
MIT (see [LICENSE](./LICENSE)).
