#!/system/bin/sh

# Wait for system to stabilize
sleep 30

# Check if daemon script exists and is executable
if [ ! -f "/system/bin/playstore-daemon.sh" ]; then
    echo "❌ Daemon script not found!" > /data/local/tmp/playstore-service.log
    exit 1
fi

if [ ! -x "/system/bin/playstore-daemon.sh" ]; then
    chmod 755 /system/bin/playstore-daemon.sh
fi

# Start daemon in background with nohup to prevent hanging
nohup /system/bin/playstore-daemon.sh > /dev/null 2>&1 &

echo "🚀 PlayStore daemon started" > /data/local/tmp/playstore-service.log
