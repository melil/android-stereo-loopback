#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion and AudioServer initialization
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 3

INSTALL_DIR="/data/local/audioloop"
mkdir -p "$INSTALL_DIR"
cp "$MODDIR/AudioLoop.jar" "$INSTALL_DIR/AudioLoop.jar"

chmod 755 "$INSTALL_DIR"
chmod 644 "$INSTALL_DIR/AudioLoop.jar"
chown -R 1000:1000 "$INSTALL_DIR"

# Restart process if running
pkill -f audioloop 2>/dev/null || true

su 1000 sh -c "CLASSPATH=$INSTALL_DIR/AudioLoop.jar exec /system/bin/app_process $INSTALL_DIR --nice-name=audioloop AudioLoop" >> "$INSTALL_DIR/loop.log" 2>&1 &
