#!/system/bin/sh

LOGFILE="/data/local/tmp/playstore-uninstall-cleanup.log"
PIDFILE="/data/local/tmp/playstore-daemon.pid"

echo "🧹 Cleaning up PlayStore daemon..." > $LOGFILE

# Kill running daemon process
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "🔪 Killing daemon process (PID: $PID)" >> $LOGFILE
        kill "$PID" 2>/dev/null
        sleep 2
        kill -9 "$PID" 2>/dev/null
    fi
    rm -f "$PIDFILE"
fi

# Kill any remaining playstore-daemon processes
killall playstore-daemon.sh 2>/dev/null

# Unlock + restore permissions
for dir in $(find /data/app -maxdepth 2 -type d -name "*com.android.vending*" 2>/dev/null); do
    if [ -f "$dir/base.apk" ]; then
        echo "🔓 Unlocking: $dir" >> $LOGFILE
        chattr -i "$dir/base.apk" 2>/dev/null
        chattr -i -R "$dir" 2>/dev/null
        chmod 644 "$dir/base.apk" 2>/dev/null
        echo "✅ Unlocked: $dir" >> $LOGFILE
    fi
done

echo "✅ Cleanup completed" >> $LOGFILE

# Clean up log files (keep cleanup log for debugging)
rm -f /data/local/tmp/playstore-lock-daemon.log
rm -f /data/local/tmp/playstore-service.log