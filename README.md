# Android USB Audio Stereo Loopback (Daemon & Magisk / KernelSU Module)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Android%20TV-3DDC84.svg?logo=android&logoColor=white)](https://developer.android.com)
[![Module](https://img.shields.io/badge/Module-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg)](https://github.com/topjohnwu/Magisk)
[![Java](https://img.shields.io/badge/Java-8%2B-ED8B00.svg?logo=openjdk&logoColor=white)](https://www.java.com)
[![Pipeline](https://img.shields.io/badge/Pipeline-Raw%20LPCM%20%7C%2016--bit%20%2F%2048kHz%20Stereo-blueviolet.svg)]()
[![Latency](https://img.shields.io/badge/Latency-Zero--Latency-brightgreen.svg)]()

Zero-latency, unkillable stereo audio passthrough for external USB Audio Interfaces on Android TV / AOSP (e.g., Ugoos X4Q, PreSonus AudioBox, Focusrite Scarlett, Behringer U-Phoria, etc.).

---

## 💡 Why this exists

Standard Android apps capturing audio (`RECORD_AUDIO`) are restricted by OS privacy and focus policies:
- **Background Muting:** They get muted immediately when the app goes to the background or screen returns home (`Activity.onPause`).
- **Audio Focus Loss:** They lose microphone/audio focus as soon as media apps (YouTube, SmartTube, Kodi, Spotify) start playback.
- **Forced Mono:** Most recording apps and system audio paths force `CHANNEL_IN_MONO`, downmixing stereo inputs into dual-mono.
- **Hardware Direct Monitor Limitations:** Hardware direct monitoring on many USB audio interfaces (such as PreSonus AudioBox iTwo) sums the two inputs into Mono hardware-side.

---

## ⚡ How it works

1. **Native Runtime Execution:** Runs directly via Android runtime (`app_process`) under **UID 1000 (`system`)**, completely independent of Android framework activity lifecycles.
2. **Immune to Lifecycles:** Never receives window lifecycle callbacks (immune to `onPause` / `onStop` / task clearing).
3. **Concurrent Background Streaming:** Retains persistent audio capture concurrently with YouTube, SmartTube, system sounds, and music players.
4. **True 48kHz Stereo Pipeline:** Captures `CHANNEL_IN_STEREO` (48,000 Hz, 16-bit PCM) and streams directly to `CHANNEL_OUT_STEREO` (`STREAM_MUSIC`).
5. **Auto-start on Boot:** Automatically launches on boot completion via Magisk / KernelSU / APatch service daemon or `service.d`.

---

## 🎛️ Step 1. Hardware Knob Setup

Set the **Direct Monitor** knob on your audio interface all the way to **Playback** (or 100% DAW).  
*Rationale:* This turns off the internal analog mono summing inside the interface, allowing Android's software pipeline to deliver pristine, isolated Left/Right channel stereo separation.

---

## 📦 Installation

### Option A: Magisk / KernelSU / APatch Module (Recommended)

1. Download **`AudioLoop-Stereo-48k-v1.0.zip`** from [Releases](https://github.com/melil/android-stereo-loopback/releases) (or build it yourself using `.\pack-release.ps1`).
2. Open **Magisk**, **KernelSU**, or **APatch** app on your Android device.
3. Go to the **Modules** tab and select **Install from storage**.
4. Select `AudioLoop-Stereo-48k-v1.0.zip`.
5. Reboot the device.

---

### Option B: Direct ADB / Shell Installation (No Module)

If you prefer not to install as a module:

```powershell
# 1. Build AudioLoop.jar on PC
.\build.ps1

# 2. Push files to the device
adb push AudioLoop.jar /data/local/tmp/
adb push install.sh /data/local/tmp/

# 3. Execute installation script as root
adb shell
su
sh /data/local/tmp/install.sh
```

---

## 🛠️ Management & Diagnostics

All management commands can be run in `adb shell` as root (`su`):

- **Check if daemon is running:**
  ```bash
  ps -ef | grep audioloop
  ```
- **Inspect daemon log:**
  ```bash
  cat /data/local/audioloop/loop.log
  ```
- **Restart / Kill daemon:**
  ```bash
  pkill -f audioloop
  ```
- **Manual Launch:**
  ```bash
  INSTALL_DIR="/data/local/audioloop"
  su 1000 sh -c "CLASSPATH=$INSTALL_DIR/AudioLoop.jar exec /system/bin/app_process $INSTALL_DIR --nice-name=audioloop AudioLoop" >> "$INSTALL_DIR/loop.log" 2>&1 &
  ```

---

## 🔨 Building from Source

### Requirements
- **JDK 8+** (Java `javac` and `jar` in `PATH`)
- Windows PowerShell (or PowerShell Core)

### Build & Package Module
Run:
```powershell
.\pack-release.ps1
```
This script will:
1. Automatically download `android.jar` and `d8.jar` if they are not already present.
2. Compile `AudioLoop.java` with Java 8 bytecode compatibility.
3. Dex the bytecode using Google's D8 compiler into `classes.dex` and package `AudioLoop.jar`.
4. Bundle `module.prop`, `service.sh`, `uninstall.sh`, and `META-INF/` into a flashable module: **`AudioLoop-Stereo-48k-v1.0.zip`**.

---

## 📁 Repository Structure

```
├── magisk/                          # Magisk / KernelSU / APatch module template
│   ├── META-INF/
│   │   └── com/google/android/
│   │       ├── update-binary        # Module installer script
│   │       └── updater-script       # Flash script identifier
│   ├── module.prop                  # Magisk module metadata
│   ├── service.sh                   # Late-start background service daemon
│   └── uninstall.sh                 # Cleanup on module removal
├── AudioLoop.java                   # Core stereo loopback implementation
├── AudioLoop.jar                    # Pre-compiled dex jar
├── AudioLoop-Stereo-48k-v1.0.zip    # Ready-to-flash module release archive
├── install.sh                       # Standalone ADB installer script
├── build.ps1                        # Script to compile AudioLoop.jar
├── pack-release.ps1                 # Script to build & package flashable zip
├── .gitignore
├── .gitattributes
└── README.md
```

---

## ⚠️ Known Limitations

- **Bluetooth Remote / Voice Search Conflict:**  
  Because the daemon holds an active, persistent `AudioRecord` session (`AudioSource.UNPROCESSED`), Android's `AudioPolicyManager` reserves the global audio input bus for this stream. On most Android TV builds, initiating voice search via a Bluetooth remote microphone will either fail or yield no audio while the loopback daemon is active.

---

## 📄 License
MIT License. Created by [melil](https://github.com/melil).