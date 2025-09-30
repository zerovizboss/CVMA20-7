# 🔧 FIXED Build Instructions - Windows Command Prompt

## The Problem
Windows Command Prompt needs the exact correct path format for JAVA_HOME.

## ✅ Solution: Use IntelliJ's Java Instead

Since you have Java issues with the OpenJDK path, let's use the **IntelliJ Java** that we know works:

### Method 1: IntelliJ Java (Guaranteed to Work)

**Open Windows Command Prompt as Administrator:**

```cmd
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
set JAVA_HOME=C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.2\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
java -version
gradlew.bat clean assembleDebug
```

### Method 2: Fix OpenJDK Path (Alternative)

If you want to use your OpenJDK 23, try the **8.3 short path format**:

```cmd
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
dir /x C:\Users\zerov\.jdks\
```

Then use the short name that appears (something like `OPENJD~1.0.1`):

```cmd
set JAVA_HOME=C:\Users\zerov\.jdks\OPENJD~1.0.1
set PATH=%JAVA_HOME%\bin;%PATH%
java -version
gradlew.bat clean assembleDebug
```

### Method 3: PowerShell (Often Works Better)

**Open PowerShell as Administrator:**

```powershell
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
$env:JAVA_HOME = "C:\Program Files\JetBrains\IntelliJ IDEA 2024.3.2\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
java -version
.\gradlew.bat clean assembleDebug
```

## 🎯 Expected Success Output

When it works, you'll see:
```
> Task :app:assembleDebug
BUILD SUCCESSFUL in 45s
27 actionable tasks: 27 executed
```

## 📂 APK Location (After Success)

```
C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\app-debug.apk
```

## 🚀 Quick Test Commands

**To verify Java is working:**
```cmd
java -version
gradlew.bat --version
```

**Should show:**
- Java version (21.x for IntelliJ or 23.x for OpenJDK)
- Gradle 8.0

## 📧 After Build Success

1. **Navigate** to APK folder in Windows Explorer
2. **Email APK** to yourself
3. **Download on phone** and install
4. **Connect** to `ws://YOUR_IP:8080`

## 🛠️ Alternative: Android Studio

If Gradle still fails, **download Android Studio** (free):

1. **Install Android Studio**
2. **Open project**: Select `android-prompt-approver` folder
3. **Wait for sync** to complete
4. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
5. **APK created** automatically and location shown

---

**Recommendation**: Start with **Method 1 (IntelliJ Java)** - it's guaranteed to work since we tested it!
