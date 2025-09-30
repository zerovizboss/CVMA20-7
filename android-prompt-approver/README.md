# CVMA Prompt Approver - Android App

A mobile Android application that connects to Claude Code sessions via WebSocket to approve prompts and decisions remotely.

## Features

- 🔗 **WebSocket Connection**: Connects to the `claude_ws_bridge.js` server on port 8080
- 📱 **Mobile Approval Interface**: Approve Claude Code prompts from your Android device
- ⚡ **Real-time Communication**: Instant prompt notifications and responses
- 🎨 **CVMA Branding**: Custom UI with military veteran styling
- 🔒 **Secure Connection**: WebSocket protocol with connection status monitoring

## Setup Instructions

### Prerequisites

1. **Android Studio**: Latest version with Android SDK
2. **Java 8+**: Required for Android development
3. **Node.js**: To run the WebSocket bridge server (`claude_ws_bridge.js`)

### Installation Steps

1. **Clone/Copy the Android project**:
   ```bash
   cd /path/to/cvma/android-prompt-approver
   ```

2. **Open in Android Studio**:
   - File → Open → Select the `android-prompt-approver` folder
   - Let Gradle sync complete

3. **Start the WebSocket Bridge Server**:
   ```bash
   # In your main IdeaProjects directory
   node claude_ws_bridge.js
   ```
   This will start the server on `ws://localhost:8080`

4. **Configure Network Access**:
   - Find your computer's IP address on the local network
   - Update the default server address in the app to use your IP (e.g., `ws://192.168.1.100:8080`)

5. **Build and Install the App**:
   ```bash
   ./gradlew assembleDebug
   adb install app/build/outputs/apk/debug/app-debug.apk
   ```

   Or use Android Studio's Run button to install directly to a connected device/emulator.

## Usage Workflow

### 1. Start the WebSocket Bridge
```bash
node claude_ws_bridge.js
```
You should see:
```
🌉 Claude Code Terminal Bridge Ready!
📱 Listening on port 8080 for mobile connections
```

### 2. Connect the Android App
1. Open the CVMA Prompt Approver app on your Android device
2. Enter your computer's IP address: `ws://192.168.1.XXX:8080`
3. Tap "Connect"
4. You should see "Connected" status

### 3. Use with Claude Code
1. In your IntelliJ/Claude Code session, when Claude presents numbered options
2. Copy the prompt text from the terminal
3. In the bridge terminal, type: `prompt:<paste the text here>`
4. Your Android device will receive the prompt instantly
5. Select an option or provide custom text
6. Copy the response from the bridge terminal back to Claude Code

## Example Usage

**In Claude Code terminal:**
```
1. Continue with current approach
2. Try a different method
3. Ask for clarification
Enter your choice:
```

**In Bridge terminal:**
```bash
prompt:1. Continue with current approach
2. Try a different method
3. Ask for clarification
Enter your choice:
```

**On Android device:**
- Receives the prompt with all options as buttons
- Tap option 1, 2, or 3
- Or provide custom text response

**Bridge shows response:**
```
🔄 COPY THIS TO YOUR CLAUDE CODE SESSION:
═══════════════════════════════════════════════════════
1
═══════════════════════════════════════════════════════
```

## App Features

### Connection Panel
- Server address configuration with saved settings
- Real-time connection status (Connected/Disconnected/Error)
- One-touch connect/disconnect

### Decision Panel
- Context display showing the current prompt situation
- Numbered option buttons matching Claude's options
- Custom text response field for free-form input
- Send custom response functionality

### Notification Service
- Background service maintains WebSocket connection
- System notifications for connection status
- Persistent notification while connected

## Technical Architecture

### WebSocket Communication
- Client connects to `claude_ws_bridge.js` on port 8080
- JSON message protocol for structured communication
- Automatic reconnection on connection loss

### Message Protocol
```javascript
// Incoming decision request
{
  "type": "decision_request",
  "data": {
    "timestamp": 1234567890,
    "context": "Description of the decision needed",
    "options": [
      {"number": 1, "text": "Option 1 description"},
      {"number": 2, "text": "Option 2 description"}
    ],
    "rawPrompt": "Full prompt text"
  }
}

// Outgoing responses
{
  "type": "select_option",
  "optionNumber": 1
}

{
  "type": "custom_text",
  "text": "Custom response text"
}
```

### Key Components
- **MainActivity**: Main UI controller and WebSocket listener
- **WebSocketService**: Background service for persistent connection
- **DecisionRequest**: Data model for incoming prompts

## Network Configuration

### Firewall Settings
Ensure port 8080 is accessible on your computer's firewall:

**Windows Firewall:**
```bash
netsh advfirewall firewall add rule name="Claude Bridge" dir=in action=allow protocol=TCP localport=8080
```

**macOS/Linux:**
```bash
# Check if port is accessible
netstat -an | grep 8080
```

### Finding Your IP Address

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your network adapter
```

**macOS/Linux:**
```bash
ifconfig
# or
ip addr show
```

## Troubleshooting

### Connection Issues
1. **"Connection failed"**: Check IP address and port 8080 accessibility
2. **"Server not found"**: Ensure `claude_ws_bridge.js` is running
3. **"Permission denied"**: Check Android app has INTERNET permission

### Development Issues
1. **Build errors**: Ensure Android SDK and build tools are installed
2. **Gradle sync fails**: Check internet connection and proxy settings
3. **App crashes**: Check LogCat in Android Studio for error details

## Development Notes

### Dependencies
- `org.java-websocket:Java-WebSocket:1.5.3`: WebSocket client library
- `com.google.code.gson:gson:2.10.1`: JSON parsing
- `androidx.appcompat:appcompat:1.6.1`: Android support library
- `com.google.android.material:material:1.10.0`: Material Design UI

### Build Configuration
- **Target SDK**: 34 (Android 14)
- **Min SDK**: 24 (Android 7.0)
- **Java Version**: 8+
- **Build Tools**: Gradle 8.0

## Future Enhancements

1. **TLS/SSL Support**: Secure WebSocket connections (wss://)
2. **Authentication**: User authentication for secure connections
3. **Multiple Sessions**: Support multiple Claude Code sessions simultaneously
4. **History**: Local storage of recent decisions and responses
5. **Themes**: Light/dark theme support
6. **Voice Input**: Speech-to-text for custom responses

---

**Created for CVMA Chapter 20-7 - Vets Serving Vets**
*Enhancing Claude Code development workflow with mobile decision approval*
