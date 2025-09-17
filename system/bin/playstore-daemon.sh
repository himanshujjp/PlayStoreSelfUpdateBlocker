#!/system/bin/sh

LOGFILE="/data/local/tmp/playstore-lock-daemon.log"
PIDFILE="/data/local/tmp/playstore-daemon.pid"

# Check if daemon is already running
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "⚠️ Daemon already running with PID $OLD_PID" >> "$LOGFILE"
        exit 0
    fi
fi

# Write current PID
echo $$ > "$PIDFILE"

# Ensure PID file is removed on exit
cleanup() {
    rm -f "$PIDFILE"
    echo "🧹 Daemon exiting, removed PID file" >> "$LOGFILE"
}
trap cleanup EXIT INT TERM

echo "🔃 Play Store Daemon Started (PID: $$)" > "$LOGFILE"
echo "📅 $(date)" >> "$LOGFILE"


# Wait briefly to let system settle
sleep 5

# Step 1: Find stock Phonesky.apk from common system partitions (broadened for more ROMs)
SYSTEM_APK=$(find /system /system_ext /product /vendor /odm /vendor_dlkm /system_root -type f -name "Phonesky.apk" -o -name "Vending.apk" 2>/dev/null | head -n 1)

if [ ! -f "$SYSTEM_APK" ]; then
    echo "❌ SYSTEM_APK not found!" >> "$LOGFILE"
    rm -f "$PIDFILE"
    exit 1
fi

# Set system APK version as stock baseline
STOCK_VER=$(timeout 10 dumpsys package com.android.vending 2>/dev/null | awk '/Package \[com.android.vending\]/, /versionCode=/' \
      | grep versionCode | head -n1 | awk -F= '{print $2}' | awk '{print $1}')

if [ -z "$STOCK_VER" ] || [ "$STOCK_VER" -eq 0 ] 2>/dev/null; then
    echo "❌ Failed to get stock version" >> "$LOGFILE"
    rm -f "$PIDFILE"
    exit 1
fi

echo "🔍 Baseline stock versionCode: $STOCK_VER" >> "$LOGFILE"

# Initialize LAST_MTIME from current installed APK if possible so we can detect changes quickly
APK_PATH_LINE=$(timeout 5 pm path com.android.vending 2>/dev/null | head -n1) || APK_PATH_LINE=""
if echo "$APK_PATH_LINE" | grep -q ':' 2>/dev/null; then
    APK_INSTALLED_PATH=$(echo "$APK_PATH_LINE" | awk -F: '{print $2}')
    if [ -f "$APK_INSTALLED_PATH" ]; then
        LAST_MTIME=$(stat -c %Y "$APK_INSTALLED_PATH" 2>/dev/null || true)
    fi
fi

# Force first loop to run a full dumpsys
checks_since_full=$FULL_CHECK_INTERVAL

# Step 2: Check if Play Store base.apk exists in /data/app
FOUND=0
if [ -d "/data/app" ]; then
    ALL_PATHS=$(find /data/app -maxdepth 2 -type f -name base.apk 2>/dev/null)
    for apk in $ALL_PATHS; do
        if echo "$apk" | grep -q "com.android.vending"; then
            FOUND=1
            echo "✅ Play Store base.apk already present at: $apk" >> "$LOGFILE"
            break
        fi
    done
fi

# Step 3: Install if not found
if [ "$FOUND" -eq 0 ]; then
    echo "📥 Installing stock Play Store from: $SYSTEM_APK" >> "$LOGFILE"
    timeout 30 pm install "$SYSTEM_APK" >> "$LOGFILE" 2>&1
    sleep 15
fi

# Step 4: Loop to monitor future self-updates every 30 seconds with lightweight checks
CHECK_COUNT=0
# Fixed 30-second monitoring with smart load management
MONITOR_INTERVAL=30          # Always check every 30 seconds
SLEEP_INTERVAL=30           # Fixed sleep time
JITTER=5                    # Small jitter to avoid sync spikes
# Run full dumpsys only when needed to reduce load
FULL_CHECK_INTERVAL=10      # Every 10 checks = ~5 minutes for full dumpsys
checks_since_full=0
LAST_MTIME=""

while true; do
    # Sleep exactly 30 seconds with small jitter to avoid sync spikes
    J=$(( (RANDOM % (JITTER*2 + 1)) - JITTER ))
    SLEEP_TIME=$(( SLEEP_INTERVAL + J ))
    if [ "$SLEEP_TIME" -lt 25 ]; then
        SLEEP_TIME=25    # Keep minimum ~25-35s range
    fi
    sleep "$SLEEP_TIME"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    checks_since_full=$((checks_since_full + 1))

    # Lightweight: try to get APK path via pm, then stat mtime
    APK_PATH_LINE=$(timeout 5 pm path com.android.vending 2>/dev/null | head -n1)
    APK_PATH=""
    if echo "$APK_PATH_LINE" | grep -q ':' 2>/dev/null; then
        APK_PATH=$(echo "$APK_PATH_LINE" | awk -F: '{print $2}')
    fi

    MTIME_CHANGED=0
    if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
        # Try stat to get modification time; if not available, fallback to forcing dumpsys periodically
        APK_MTIME=$(stat -c %Y "$APK_PATH" 2>/dev/null || true)
        if [ -n "$APK_MTIME" ] && [ "$APK_MTIME" != "$LAST_MTIME" ]; then
            MTIME_CHANGED=1
            LAST_MTIME="$APK_MTIME"
        fi
    fi

    # Decide whether to run heavy dumpsys check
    if [ "$MTIME_CHANGED" -eq 1 ] || [ "$checks_since_full" -ge "$FULL_CHECK_INTERVAL" ]; then
        checks_since_full=0
        # Add timeout to prevent hanging
        CUR_VER=$(timeout 15 dumpsys package com.android.vending 2>/dev/null | awk '/Package \[com.android.vending\]/, /versionCode=/' \
           | grep versionCode | head -n1 | awk -F= '{print $2}' | awk '{print $1}')
    else
        # Skip dumpsys; reuse last known version if available by trying a quick pm dump (fallback)
        CUR_VER=""
    fi

    # Handle empty/invalid version
    if [ -z "$CUR_VER" ]; then
        echo "⚠️ Check #$CHECK_COUNT - no dumpsys run (mt_changed=$MTIME_CHANGED)" >> "$LOGFILE"
        # increase backoff gradually up to MAX_BACKOFF
        BACKOFF=$(( BACKOFF * 2 ))
        if [ "$BACKOFF" -gt "$MAX_BACKOFF" ]; then
            BACKOFF=$MAX_BACKOFF
        fi
        continue
    fi

    echo "📦 Check #$CHECK_COUNT - versionCode: $CUR_VER (mt_changed=$MTIME_CHANGED)" >> "$LOGFILE"

    # Only act if version is higher
    if [ "$CUR_VER" -gt "$STOCK_VER" ]; then
        echo "⚠️ Self-update detected! ($CUR_VER > $STOCK_VER)" >> "$LOGFILE"
        echo "🔄 Uninstalling updates..." >> "$LOGFILE"

        timeout 30 pm uninstall com.android.vending >> "$LOGFILE" 2>&1
        sleep 10

        echo "📥 Reinstalling stock Play Store..." >> "$LOGFILE"
        timeout 30 pm install "$SYSTEM_APK" >> "$LOGFILE" 2>&1
        sleep 15

        echo "✅ Restored to stock version" >> "$LOGFILE"

        # Continue with 30s monitoring after restoration
    else
        # No change detected - continue with same 30s interval
        # (no backoff since you want consistent 30s monitoring)
        echo "📊 No update detected, continuing 30s monitoring..." >> "$LOGFILE"
    fi

    # Trim log file occasionally (every ~1 hour depending on backoff)
    if [ $((CHECK_COUNT % 120)) -eq 0 ]; then
        MAX_LINES=500
        if [ -f "$LOGFILE" ]; then
            tail -n $MAX_LINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        fi
    fi
done
