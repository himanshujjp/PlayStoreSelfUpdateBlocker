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

echo "🔃 Play Store Daemon Started (PID: $$)" > "$LOGFILE"
echo "📅 $(date)" >> "$LOGFILE"

sleep 30

# Step 1: Find stock Phonesky.apk from system
SYSTEM_APK=$(find /system /system_ext /product /vendor -type f -name Phonesky.apk 2>/dev/null | head -n 1)

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

# Step 4: Loop to monitor future self-updates with longer intervals
CHECK_COUNT=0
while true; do
    # Longer sleep to reduce system load
    sleep 300  # 5 minutes instead of 10 seconds
    
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    # Add timeout to prevent hanging
    CUR_VER=$(timeout 15 dumpsys package com.android.vending 2>/dev/null | awk '/Package \[com.android.vending\]/, /versionCode=/' \
       | grep versionCode | head -n1 | awk -F= '{print $2}' | awk '{print $1}')

    # Handle empty/invalid version
    if [ -z "$CUR_VER" ] || ! [ "$CUR_VER" -eq "$CUR_VER" ] 2>/dev/null; then
        echo "⚠️ Failed to get current version (check #$CHECK_COUNT)" >> "$LOGFILE"
        continue
    fi

    echo "📦 Check #$CHECK_COUNT - versionCode: $CUR_VER" >> "$LOGFILE"
    
    # Only act if version is significantly higher
    if [ "$CUR_VER" -gt "$STOCK_VER" ]; then
        echo "⚠️ Self-update detected! ($CUR_VER > $STOCK_VER)" >> "$LOGFILE"
        echo "🔄 Uninstalling updates..." >> "$LOGFILE"
        
        timeout 30 pm uninstall com.android.vending >> "$LOGFILE" 2>&1
        sleep 10
        
        echo "📥 Reinstalling stock Play Store..." >> "$LOGFILE"
        timeout 30 pm install "$SYSTEM_APK" >> "$LOGFILE" 2>&1
        sleep 15
        
        echo "✅ Restored to stock version" >> "$LOGFILE"
    fi

    # Trim log file every 20 checks
    if [ $((CHECK_COUNT % 20)) -eq 0 ]; then
        MAX_LINES=200
        if [ -f "$LOGFILE" ]; then
            tail -n $MAX_LINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        fi
    fi
done
