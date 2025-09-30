# 🚀 Build APK with OpenJDK 23 - Complete Instructions

## Method 1: Windows Command Prompt (Recommended)

### Step 1: Open Command Prompt as Administrator
- Press **Windows Key + X**
- Select **"Windows Terminal (Admin)"** or **"Command Prompt (Admin)"**

### Step 2: Navigate to Android Project
```cmd
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
```

### Step 3: Set OpenJDK 23 Environment
```cmd
set JAVA_HOME=C:\Users\zerov\.jdks\openjdk-23.0.1
set PATH=%JAVA_HOME%\bin;%PATH%
java -version
```

### Step 4: Clean Build (Important!)
```cmd
rmdir /s /q %USERPROFILE%\.gradle\caches
gradlew.bat clean
gradlew.bat assembleDebug
```

If that fails, try:
```cmd
gradlew.bat --no-daemon clean assembleDebug
```

## Method 2: PowerShell Alternative

```powershell
cd C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver
$env:JAVA_HOME = "C:\Users\zerov\.jdks\openjdk-23.0.1"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
.\gradlew.bat clean assembleDebug
```

## 📂 APK Location

**Success! Your APK will be at:**
```
C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\app-debug.apk
```

**File size**: ~5-10 MB
**File name**: `app-debug.apk`

## 📧 Install on Phone - Complete Steps

### Step A: Email Method
1. **Navigate in Windows Explorer**:
   `C:\Users\zerov\IdeaProjects\cvma\android-prompt-approver\app\build\outputs\apk\debug\`
2. **Right-click** `app-debug.apk` → **Send to** → **Mail recipient**
3. **Email to yourself**

### Step B: Phone Installation
1. **Download APK** from email on your Android phone
2. **Enable Unknown Sources**:
   - **Android 8+**: Settings → Apps → Special app access → Install unknown apps → [Your Browser/Gmail] → Allow
   - **Android 7-**: Settings → Security → Unknown sources → Enable
3. **Tap APK** in Downloads to install
4. **Grant permissions** if requested

### Step C: Connect to WebSocket Bridge
1. **Open CVMA Prompt Approver** app
2. **Server Address**: `ws://192.168.1.XXX:8080` (replace XXX with your computer's IP)
3. **Find your IP**: Run `ipconfig` in Command Prompt, look for IPv4 Address
4. **Tap Connect**
5. **Status should show**: "Connected"

## 🧪 Complete System Test

### Test 1: Basic Connection
1. **WebSocket bridge running**: ✅ (already running on port 8080)
2. **Phone connected**: Should show "Connected" status
3. **Bridge shows**: "✅ Mobile device connected!"

### Test 2: Prompt Approval
1. **In bridge terminal**, type:
   ```
   prompt:1. Continue with current approach
   2. Try alternative method
   3. Ask for clarification
   Enter your choice:
   ```
2. **Phone should receive**: Notification and show decision panel
3. **Tap option 2** on phone
4. **Bridge shows**: "📝 Selected option: 2"
5. **Copy response**: "2" back to your Claude Code session

## 🛠️ Troubleshooting

### Build Issues
- **"Java not found"**: Make sure JAVA_HOME points to your OpenJDK 23 installation
- **"Gradle cache error"**: Delete `%USERPROFILE%\.gradle\caches` and try again
- **"Permission denied"**: Run Command Prompt as Administrator

### Phone Issues
- **"App not installed"**: Enable Unknown Sources for your file manager/browser
- **"Connection failed"**: Check firewall allows port 8080, verify IP address
- **"Parse error"**: APK may be corrupted, rebuild and re-download

### Network Issues
- **Can't connect**: Your computer and phone must be on same WiFi network
- **Firewall blocking**: Add rule for port 8080
- **Wrong IP**: Use `ipconfig` to get correct IPv4 address

## 🎯 Success Criteria

✅ **APK builds without errors**
✅ **App installs on Android phone**
✅ **WebSocket connection established**
✅ **Prompt approval workflow works**
✅ **Bridge receives and displays responses**

**Ready for production use with Claude Code development sessions!**

---

**Your OpenJDK 23 is perfect for this build - it's the latest stable Java version!**
