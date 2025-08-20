#!/system/bin/sh

LOGFILE="/data/local/tmp/playstore-lock-daemon.log"

echo "🧹 Cleaning up..." > $LOGFILE

# Unlock + restore permissions
for dir in $(find /data/app -type d -name "*com.android.vending*" 2>/dev/null); do
    if [ -f "$dir/base.apk" ]; then
        echo "🔓 Unlocking: $dir" >> $LOGFILE
        chattr -i "$dir/base.apk"
        chattr -i -R "$dir"
        chmod 644 "$dir/base.apk"
        echo "✅ Unlocked: $dir" >> $LOGFILE
    fi
done

# 🔥 Delete logs
rm -f /data/local/tmp/playstore-lock-daemon.log
rm -f /data/local/tmp/playstore-uninstall-cleanup.log