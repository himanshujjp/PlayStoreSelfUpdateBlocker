#!/system/bin/sh

LOGFILE="/data/local/tmp/playstore-lock-daemon.log"
echo "🔃 Play Store Daemon Started" > "$LOGFILE"

sleep 10

# Step 1: Find stock Phonesky.apk from system
SYSTEM_APK=$(find /system /system_ext /product /vendor -type f -name Phonesky.apk 2>/dev/null | head -n 1)

if [ ! -f "$SYSTEM_APK" ]; then
    echo "❌ SYSTEM_APK not found!" >> "$LOGFILE"
    exit 1
fi

# Set system APK version as stock baseline
STOCK_VER=$(dumpsys package com.android.vending | awk '/Package \[com.android.vending\]/, /versionCode=/' \
      | grep versionCode | head -n1 | awk -F= '{print $2}' | awk '{print $1}')
echo "🔍 Baseline stock versionCode: $STOCK_VER" >> "$LOGFILE"


# Step 2: Check if Play Store base.apk exists in /data/app
FOUND=0
ALL_PATHS=$(find /data/app -type f -name base.apk 2>/dev/null)
for apk in $ALL_PATHS; do
    if echo "$apk" | grep -q "com.android.vending"; then
        FOUND=1
        echo "✅ Play Store base.apk already present at: $apk" >> "$LOGFILE"
        break
    fi
done

# Step 3: Install if not found
if [ "$FOUND" -eq 0 ]; then
    echo "📥 Installing stock Play Store from: $SYSTEM_APK" >> "$LOGFILE"
    pm install "$SYSTEM_APK" >> "$LOGFILE" 2>&1
    sleep 10
fi




# Step 4: Loop to monitor future self-updates
while true; do
    sleep 10
    CUR_PATH=$(dumpsys package com.android.vending | grep codePath | cut -d= -f2)
    
    CUR_VER=$(dumpsys package com.android.vending | awk '/Package \[com.android.vending\]/, /versionCode=/' \
   | grep versionCode | head -n1 | awk -F= '{print $2}' | awk '{print $1}')

    echo "📦 Installed versionCode: $CUR_VER" >> "$LOGFILE"
    
    if [ "$CUR_VER" -gt "$STOCK_VER" ]; then
        echo "⚠️ Self-update detected! Uninstalling..." >> "$LOGFILE"
        pm uninstall com.android.vending >> "$LOGFILE" 2>&1
        sleep 5
        echo "📥 Installing stock Play Store from: $SYSTEM_APK" >> "$LOGFILE"
    pm install "$SYSTEM_APK" >> "$LOGFILE" 2>&1
         sleep 5
    fi

    # Trim log file
    MAX_LINES=100
    tail -n $MAX_LINES "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
done
