#!/system/bin/sh
set -e

echo "[*] Installing Android Stereo Loopback..."

INSTALL_DIR="/data/local/audioloop"
SERVICE_DIR="/data/adb/service.d"

# 1. Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "[-] Error: Run this script as root (su)"
    exit 1
fi

# 2. Create directory and configure permissions for system user (UID 1000)
mkdir -p "$INSTALL_DIR"
if [ -f "/data/local/tmp/AudioLoop.jar" ]; then
    mv /data/local/tmp/AudioLoop.jar "$INSTALL_DIR/AudioLoop.jar"
fi

if [ ! -f "$INSTALL_DIR/AudioLoop.jar" ]; then
    echo "[-] Error: AudioLoop.jar not found! Push it to /data/local/tmp/ first."
    exit 1
fi

chmod 755 "$INSTALL_DIR"
chmod 644 "$INSTALL_DIR/AudioLoop.jar"
chown -R 1000:1000 "$INSTALL_DIR"

# 3. Configure Magisk service
mkdir -p "$SERVICE_DIR"
cat << 'EOF' > "$SERVICE_DIR/audioloop.sh"
#!/system/bin/sh
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
    done
    sleep 3
    su 1000 sh -c "CLASSPATH=/data/local/audioloop/AudioLoop.jar exec /system/bin/app_process /data/local/audioloop --nice-name=audioloop AudioLoop" >> /data/local/audioloop/loop.log 2>&1
) &
EOF

chmod 755 "$SERVICE_DIR/audioloop.sh"

# 4. Start daemon immediately
pkill -f audioloop 2>/dev/null || true
sh "$SERVICE_DIR/audioloop.sh"

sleep 1
if ps -ef | grep -v grep | grep audioloop > /dev/null; then
    echo "[+] SUCCESS: audioloop is running as system service!"
else
    echo "[-] Warning: Process started, check log: cat $INSTALL_DIR/loop.log"
fi