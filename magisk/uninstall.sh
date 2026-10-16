#!/system/bin/sh
pkill -f audioloop 2>/dev/null || true
rm -rf /data/local/audioloop
rm -f /data/adb/service.d/audioloop.sh
