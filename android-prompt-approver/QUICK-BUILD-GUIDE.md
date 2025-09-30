# 🚀 Quick Build Guide - CVMA Prompt Approver

## Prerequisites Needed

### 1. Install Java JDK
**Download**: https://adoptium.net/temurin/releases/
- Choose **JDK 17** (LTS version)
- Download **Windows x64 MSI installer**
- Run installer with default settings
- **Restart your computer after installation**

### 2. Build Methods

#### Method A: Using Windows Command Prompt (Recommended)
```cmd
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
gradlew.bat assembleDebug
```

#### Method B: Using PowerShell
```powershell
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
.\gradlew.bat assembleDebug
```

## 📂 APK Location After Build

**Your APK will be created at:**
```
C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\app-debug.apk
```

## 📧 Email the APK

1. **Navigate to the APK location** in Windows Explorer
2. **Right-click** on `app-debug.apk`
3. **Send to** → **Mail recipient**
4. **Email it to yourself**
5. **Download on your phone** and install

## 🔧 Alternative: Manual APK Creation

If Gradle fails, you can also:
1. **Install Android Studio** (free from Google)
2. **Open the project**: `android-prompt-approver` folder
3. **Click the green Run button**
4. **Select "Build APK"** from the Build menu

## 📱 Installing on Phone

1. **Enable Unknown Sources**: Settings → Security → Unknown Sources
2. **Download APK** from your email on phone
3. **Tap the APK file** to install
4. **Open the app** and connect to your WebSocket bridge

## 🌐 Connection Settings

Once the app is installed:
- **Server Address**: `ws://192.168.1.YOUR_IP:8080`
- **Find Your IP**: Run `ipconfig` in Windows Command Prompt
- **Look for**: IPv4 Address under your active network

## 🎯 Quick Test

Your WebSocket bridge is already running! Just:
1. Build APK → Email → Install on phone → Connect
2. In the bridge terminal, type: `prompt:Test message`
3. Your phone should receive the test prompt!

---

**The simplest path**: Install Java JDK 17, then run the build command in Windows Command Prompt!
