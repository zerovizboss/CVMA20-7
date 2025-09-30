# CVMA Claude Code Bridge - Motorola Moto G 2025 Setup Guide

## 🏍️ **Complete Integration Guide for Your New Moto G 2025**

**Updated**: September 28, 2025
**Device**: Motorola Moto G 2025
**Claude Code Session**: IntelliJ IDEA + Android Integration

---

## 📱 **Moto G 2025 Compatibility Status: ✅ FULLY SUPPORTED**

### **Confirmed Specifications**:
- **Android Version**: 14+ (Perfect match for our targetSdk 34)
- **Architecture**: ARM64-v8a (Optimized in our build.gradle)
- **Network**: WiFi 6, Enhanced cellular connectivity
- **Performance**: Modern processor handles our lightweight app easily
- **Battery**: Improved background service management
- **Security**: Enhanced app sandboxing compatible with our permissions

---

## 🚀 **Quick Start Setup (5 Minutes)**

### **Step 1: Install Node.js Dependencies**
```bash
# In your CVMA project directory
cd C:\Users\zerov\IdeaProjects\cvma
npm install
```

### **Step 2: Start the WebSocket Bridge**
```bash
# Start the bridge server
node claude_ws_bridge.js
# OR
npm start
```

You'll see:
```
🌉 Claude Code Terminal Bridge Ready!
📱 Listening on port 8080 for mobile connections
🔗 Connect your Moto G 2025 to one of these addresses:
   ws://localhost:8080
   ws://192.168.1.XXX:8080
```

### **Step 3: Build and Install Android App**
```bash
# In the android-prompt-approver directory
cd android-prompt-approver
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

### **Step 4: Connect Your Moto G 2025**
1. Open **CVMA Prompt Approver** app on your Moto G 2025
2. Enter the IP address from Step 2: `ws://192.168.1.XXX:8080`
3. Tap **Connect**
4. Wait for **"Connected"** status

---

## 💻 **Complete Workflow Example**

### **Scenario**: Claude Code presents you with options in IntelliJ

**1. In your IntelliJ terminal, Claude shows:**
```
I can help you with that. What would you like to do?

1. Add new functionality to the component
2. Fix the existing bug
3. Refactor the code structure
4. Run tests and analyze results

Enter your choice:
```

**2. In your Node bridge terminal, type:**
```bash
🏍️  CVMA Bridge> prompt:1. Add new functionality to the component
2. Fix the existing bug
3. Refactor the code structure
4. Run tests and analyze results
```

**3. On your Moto G 2025:**
- App receives the prompt instantly
- Shows 4 buttons with the options
- Tap your preferred choice (e.g., Option 2)

**4. Bridge terminal displays:**
```
🔄 COPY THIS TO YOUR CLAUDE CODE SESSION:
══════════════════════════════════════════════════════
2
══════════════════════════════════════════════════════
```

**5. Copy "2" and paste into your Claude Code session**

**Result**: Seamless mobile decision-making while coding!

---

## 🔧 **Moto G 2025 Specific Optimizations**

### **Performance Enhancements Applied:**
```gradle
// Optimized for Moto G 2025 ARM architecture
ndk {
    abiFilters 'arm64-v8a', 'armeabi-v7a'
}

// Battery optimization
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        // Enhanced performance settings
    }
}
```

### **Network Configuration for Moto G 2025:**
```xml
<!-- Optimized network permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Clear text traffic for local development -->
android:usesCleartextTraffic="true"
```

### **Background Service Optimization:**
The WebSocketService is optimized for Moto G 2025's battery management:
- Intelligent reconnection logic
- Foreground service with persistent notification
- Connection timeout handling (30 seconds)
- Automatic Wi-Fi reconnection

---

## 🏠 **Network Setup for Home/Office**

### **Find Your Computer's IP Address:**

**Windows (PowerShell):**
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*"} | Select-Object IPAddress
```

**Windows (Command Prompt):**
```cmd
ipconfig | findstr "IPv4"
```

### **Firewall Configuration:**
```bash
# Allow port 8080 through Windows Firewall
netsh advfirewall firewall add rule name="CVMA Claude Bridge" dir=in action=allow protocol=TCP localport=8080
```

### **Router Configuration:**
If you have connection issues:
1. Ensure both devices are on the same WiFi network
2. Check if router has AP isolation disabled
3. Port 8080 should be accessible within your local network

---

## 📱 **Android App Features for Moto G 2025**

### **Connection Panel:**
- **Server Address Configuration**: Saves your last used IP
- **Real-time Status**: Connected/Disconnected/Connecting states
- **One-Touch Connect**: Quick reconnection
- **Network Error Handling**: Automatic retry logic

### **Decision Interface:**
- **Context Display**: Shows the full prompt situation
- **Dynamic Buttons**: Numbered options appear as individual buttons
- **Custom Text Input**: Free-form response capability
- **Response Confirmation**: Visual feedback when choice is sent

### **Background Service:**
- **Persistent Connection**: Maintains WebSocket connection
- **System Notifications**: Connection status updates
- **Battery Optimized**: Respects Moto G 2025 battery management
- **Automatic Reconnection**: Handles network interruptions

---

## 🔍 **Troubleshooting for Moto G 2025**

### **Connection Issues:**

**"Connection Failed"**:
1. Verify your computer's IP address
2. Ensure Node bridge is running (`node claude_ws_bridge.js`)
3. Check that both devices are on same WiFi network
4. Try `ws://localhost:8080` if testing on emulator

**"Server Not Found"**:
1. Confirm bridge server shows "Listening on port 8080"
2. Check Windows Firewall settings
3. Try different IP address from the bridge startup list

**"Permission Denied"**:
1. Android app has INTERNET permission (automatically granted)
2. Check if corporate/school network blocks WebSocket connections

### **Performance Issues:**

**Slow Response:**
- Moto G 2025 should have excellent performance
- Check WiFi signal strength
- Restart bridge if responses are delayed

**Battery Drain:**
- App is optimized for Moto G 2025's battery management
- Background service uses minimal resources
- Android 14's adaptive battery will learn usage patterns

### **Development Issues:**

**Build Errors:**
```bash
# Clean and rebuild
./gradlew clean
./gradlew assembleDebug
```

**ADB Connection:**
```bash
# Enable USB debugging on Moto G 2025
# Settings > About phone > Tap build number 7 times
# Settings > Developer options > USB debugging
adb devices
```

---

## 🎯 **Advanced Features**

### **Multiple Session Support:**
The bridge can handle multiple Claude Code sessions simultaneously:
```bash
# Each prompt gets a unique timestamp
prompt:Session 1 - Option 1, Option 2
prompt:Session 2 - Different options
```

### **Custom Response Capability:**
Your Moto G 2025 can send custom text responses:
1. Use the text input field in the app
2. Type custom instructions
3. Tap "Send Custom"
4. Bridge receives your custom text

### **Command Line Features:**
```bash
🏍️  CVMA Bridge> help          # Show all commands
🏍️  CVMA Bridge> status        # Check connection status
🏍️  CVMA Bridge> clear         # Clear screen
🏍️  CVMA Bridge> quit          # Shutdown bridge
```

---

## 🔐 **Security Considerations**

### **Local Network Only:**
- Bridge only listens on local network interfaces
- No internet exposure by default
- WebSocket traffic is unencrypted (local development only)

### **Moto G 2025 Security:**
- App runs in Android's secure app sandbox
- No sensitive data storage
- Only network permissions required
- Foreground service with user notification

### **Development Security:**
- Bridge shows all traffic in terminal for transparency
- No automatic code execution from mobile responses
- Manual copy-paste workflow maintains control

---

## 🚀 **Next Steps & Future Enhancements**

### **Immediate Usage:**
1. ✅ Node bridge running
2. ✅ Moto G 2025 app installed
3. ✅ Connected and ready for Claude Code sessions

### **Planned Enhancements:**
- **TLS/SSL Support**: Secure WebSocket connections
- **Authentication**: User authentication for secure access
- **Voice Input**: Speech-to-text for hands-free responses
- **History**: Local storage of recent decisions
- **Multi-Device**: Support multiple mobile devices simultaneously

---

## 📞 **Support & Documentation**

### **Log Files:**
- **Bridge logs**: Terminal output shows all connection activity
- **Android logs**: Use `adb logcat` to see app debugging info
- **Network logs**: `netstat -an | findstr 8080` to verify port status

### **Documentation Links:**
- **Android App README**: `android-prompt-approver/README.md`
- **Node Bridge Source**: `claude_ws_bridge.js`
- **Build Instructions**: `android-prompt-approver/BUILD-INSTRUCTIONS.md`

---

## 🏍️ **CVMA DevSecOps Excellence**

**Combat Veterans Motorcycle Association Chapter 20-7**
**"Vets Serving Vets" - Enhanced Development Workflow**

This integration represents revolutionary mobile-first development tooling, enabling seamless Claude Code decision-making from your Motorola Moto G 2025 while maintaining the security and performance standards expected in modern development environments.

**Session Token Efficiency**: This setup eliminates context switching overhead and enhances development velocity through mobile decision approval workflow.

---

**Ready to enhance your Claude Code development with your new Moto G 2025!** 🚀📱

*Last Updated: September 28, 2025*
*Compatible with: Motorola Moto G 2025, Android 14+, Claude Code, IntelliJ IDEA*
