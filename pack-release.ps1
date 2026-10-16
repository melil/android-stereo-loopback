$ErrorActionPreference = "Stop"

# 1. Check dependencies (javac, android.jar, d8.jar)
if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
    Write-Error "JDK (javac) not found in PATH!"
}

if (-not (Test-Path "android.jar")) {
    Write-Host "Downloading android.jar..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sable/android-platforms/master/android-28/android.jar" -OutFile "android.jar"
}

if (-not (Test-Path "d8.jar")) {
    Write-Host "Downloading d8.jar (R8 compiler)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://dl.google.com/android/maven2/com/android/tools/r8/8.2.42/r8-8.2.42.jar" -OutFile "d8.jar"
}

# 2. Compile 48kHz AudioLoop code
Write-Host "Compiling 48kHz AudioLoop..." -ForegroundColor Cyan
Remove-Item AudioLoop.class, classes.dex, AudioLoop.jar -ErrorAction SilentlyContinue
javac -source 8 -target 8 -cp android.jar AudioLoop.java
java -cp d8.jar com.android.tools.r8.D8 --lib android.jar --output . AudioLoop.class
jar -cf AudioLoop.jar classes.dex
Remove-Item AudioLoop.class, classes.dex -ErrorAction SilentlyContinue

# 3. Assemble module structure from magisk/ directory
$distDir = "dist"
if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
Copy-Item -Path "magisk" -Destination $distDir -Recurse
Copy-Item "AudioLoop.jar" "$distDir/"

# 4. Package to ZIP
$zipName = "AudioLoop-Stereo-48k-v1.0.zip"
if (Test-Path $zipName) { Remove-Item $zipName }

# Use jar -cMf to ensure standard Unix forward slashes (/) for 100% Magisk / KernelSU compatibility
if (Get-Command jar -ErrorAction SilentlyContinue) {
    jar -cMf $zipName -C $distDir .
} else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        (Resolve-Path $distDir),
        (Resolve-Path .).Path + "\$zipName"
    )
}

Remove-Item -Recurse -Force $distDir
Write-Host "`nBUILD SUCCESS: $zipName ready for distribution!" -ForegroundColor Green
