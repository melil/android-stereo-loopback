$ErrorActionPreference = "Stop"

Write-Host "[1/4] Checking dependencies..."
if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
    Write-Error "JDK (javac) not found in PATH!"
}

# Download android.jar (API 28 stub) if missing
if (-not (Test-Path "android.jar")) {
    Write-Host "[2/4] Downloading android.jar..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Sable/android-platforms/master/android-28/android.jar" -OutFile "android.jar"
}

# Download Google D8 compiler if missing
if (-not (Test-Path "d8.jar")) {
    Write-Host "[3/4] Downloading d8.jar (R8 compiler)..."
    Invoke-WebRequest -Uri "https://dl.google.com/android/maven2/com/android/tools/r8/8.2.42/r8-8.2.42.jar" -OutFile "d8.jar"
}

Write-Host "[4/4] Compiling to classes.dex..."
javac -source 8 -target 8 -cp android.jar AudioLoop.java
java -cp d8.jar com.android.tools.r8.D8 --lib android.jar --output . AudioLoop.class
jar -cf AudioLoop.jar classes.dex

# Clean up temporary compilation artifacts
Remove-Item AudioLoop.class, classes.dex -ErrorAction SilentlyContinue

Write-Host "`nSUCCESS: AudioLoop.jar built successfully!" -ForegroundColor Green