# 🔨 APK Build Instructions - Immediate Action Required

## 🎯 Simplest Method: Use Windows Command Prompt

### Step 1: Open Windows Command Prompt (Not Git Bash)
- Press **Windows Key + R**
- Type: `cmd`
- Press **Enter**

### Step 2: Navigate to the Android Project
```cmd
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
```

### Step 3: Set Java Environment (if needed)
```cmd
set JAVA_HOME=C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.2\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
```

### Step 4: Clean and Build APK
```cmd
gradlew.bat clean
gradlew.bat assembleDebug
```

## 📂 APK Location After Successful Build

**Your APK will be at:**
```
C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\app-debug.apk
```

## 📧 Email the APK to Yourself

1. **Open Windows Explorer**
2. **Navigate to**: `C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\`
3. **Right-click** on `app-debug.apk`
4. **Send to** → **Mail recipient**
5. **Email to yourself**

## 📱 Install on Android Phone

1. **Download APK** from email on your phone
2. **Enable Unknown Sources**: Settings → Security → Install unknown apps → Enable for your browser/file manager
3. **Tap APK file** to install
4. **Open app** → Enter your computer's IP address: `ws://192.168.1.XXX:8080`
5. **Tap Connect**

## 🌐 Find Your Computer's IP Address
```cmd
ipconfig
```
Look for **IPv4 Address** under your active network adapter.

## 🚀 Test the Complete System

1. **WebSocket Bridge**: Already running on port 8080 ✅
2. **Build APK**: Follow steps above
3. **Install on phone**: Via email method
4. **Connect**: Use your IP address
5. **Test**: In bridge terminal, type: `prompt:1. Test option 1\n2. Test option 2\nEnter choice:`

## 🛠️ Alternative: Android Studio Method

If the command line fails:
1. **Download Android Studio** (free)
2. **Open project**: `android-prompt-approver` folder
3. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
4. **APK created** automatically

---

**The fastest path**: Use Windows Command Prompt with the `gradlew.bat` commands above!
