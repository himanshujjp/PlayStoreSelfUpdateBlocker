# 🚫 PlayStoreSelfUpdateBlocker (PUSBlocker)

Prevents the **Google Play Store** from auto-updating itself with **real-time monitoring** and automatic rollback. Designed for users maintaining device attestation under the **Play Integrity API** rules.

> ⚠️ Disclaimer: Educational/experimental use only. Use at your own risk. You are responsible for complying with local laws and app policies.

## Details
- **Module ID:** PUSBlocker
- **Version:** 2.0 (Enhanced Monitoring)
- **Author:** @himanjjp
- **Requires:** Root + Magisk, APatch, or KernelSU
- **Detection Speed:** 30-second monitoring intervals
- **System Load:** Optimized with adaptive lightweight checks

## What it does
- **Real-time monitoring**: Checks for Play Store self-updates every 30 seconds
- **Automatic rollback**: Instantly reverts to stock version when update detected
- **Multi-ROM support**: Works across AOSP, OEM, and custom ROM variants
- **Load optimized**: Uses lightweight checks with minimal system impact
- **Intelligent detection**: Combines file modification tracking with version checks

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

## How It Works

### Smart Detection System
1. **Lightweight monitoring**: Every 30 seconds, checks APK modification time (`stat` + `pm path`)
2. **Heavy validation**: Full `dumpsys` check only when file changes or every 5 minutes
3. **Instant response**: When update detected → uninstall → reinstall stock → resume monitoring

### System Load Optimization
- **Adaptive backoff**: Reduces frequency when no changes detected
- **Jitter protection**: Randomized timing prevents system sync spikes
- **Timeout protection**: All operations have 15-30s timeouts to prevent hanging
- **Process cleanup**: Proper PID management and exit handlers

## Testing & Validation

### Quick Test Commands
```bash
# Push and install daemon
adb push system/bin/playstore-daemon.sh /data/local/tmp/
adb shell su -c 'cp /data/local/tmp/playstore-daemon.sh /system/bin/ && chmod 0755 /system/bin/playstore-daemon.sh'

# Start daemon manually
adb shell su -c '/system/bin/playstore-daemon.sh &'

# Monitor logs in real-time
adb shell su -c 'tail -f /data/local/tmp/playstore-lock-daemon.log'
```

### Expected Log Output
```
🔃 Play Store Daemon Started (PID: 12345)
📅 Wed Sep 17 15:30:00 UTC 2025
🔍 Baseline stock versionCode: 82441300
📦 Check #1 - versionCode: 82441300 (mt_changed=1)
📦 Check #2 - versionCode: 82441300 (mt_changed=0)
⚠️ Self-update detected! (84210600 > 82441300)
🔄 Uninstalling updates...
📥 Reinstalling stock Play Store...
✅ Restored to stock version
```

### Performance Monitoring
- **Average CPU usage**: <0.1% on modern devices
- **Memory footprint**: ~2MB RSS
- **Detection latency**: 25-35 seconds (with jitter)
- **Heavy operations**: dumpsys runs max every 5 minutes

## Troubleshooting
- **Updates still occurring**: Check logs for detection events and error messages
- **High CPU usage**: Verify script is using adaptive intervals (check log timing)
- **Daemon not starting**: Ensure root permissions and verify APK paths in logs
- **Detection delays**: Normal 30s intervals; check mtime detection in logs

## Changelog

### v2.0 (Enhanced Monitoring)
- **NEW:** Real-time 30-second monitoring with instant rollback
- **NEW:** Multi-ROM APK detection (AOSP, OEM, custom partitions)
- **NEW:** Intelligent load management with adaptive lightweight checks
- **NEW:** APK modification time tracking for immediate update detection
- **IMPROVED:** Reduced system load while maintaining fast response times
- **ADDED:** Comprehensive logging with performance metrics
- **ADDED:** Jitter protection against synchronized polling spikes
- **ENHANCED:** Better compatibility across different Android ROM variants

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
