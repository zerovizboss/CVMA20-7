#!/usr/bin/env node

/**
 * CVMA Claude Code WebSocket Bridge
 *
 * Bridges communication between Claude Code sessions in IntelliJ/terminal
 * and the CVMA Prompt Approver Android app on Motorola Moto G 2025.
 *
 * Usage:
 *   node claude_ws_bridge.js
 *
 * Then in terminal when Claude presents options:
 *   prompt:1. Option one
 *   2. Option two
 *   3. Option three
 *
 * @author CVMA Development Team
 * @date September 28, 2025
 */

const WebSocket = require('ws');
const readline = require('readline');
const os = require('os');

class ClaudeWebSocketBridge {
    constructor(port = 8080) {
        this.port = port;
        this.server = null;
        this.clients = new Set();
        this.currentRequest = null;
        this.rl = null;

        this.initializeServer();
        this.initializeCommandLine();
        this.displayWelcome();
    }

    initializeServer() {
        this.server = new WebSocket.Server({
            port: this.port,
            host: '0.0.0.0' // Listen on all interfaces for mobile access
        });

        this.server.on('connection', (ws, req) => {
            const clientIP = req.socket.remoteAddress;
            console.log(`📱 Android device connected from ${clientIP}`);

            this.clients.add(ws);

            // Send connection confirmation
            this.sendToClient(ws, {
                type: 'connection_confirmed',
                data: {
                    timestamp: Date.now(),
                    message: 'Connected to CVMA Claude Bridge'
                }
            });

            ws.on('message', (data) => {
                try {
                    const message = JSON.parse(data.toString());
                    this.handleClientMessage(message);
                } catch (error) {
                    console.error('❌ Error parsing client message:', error.message);
                }
            });

            ws.on('close', () => {
                console.log('📱 Android device disconnected');
                this.clients.delete(ws);
            });

            ws.on('error', (error) => {
                console.error('❌ WebSocket error:', error.message);
                this.clients.delete(ws);
            });
        });

        this.server.on('listening', () => {
            const interfaces = this.getNetworkInterfaces();
            console.log(`🌉 Claude Code Terminal Bridge Ready!`);
            console.log(`📱 Listening on port ${this.port} for mobile connections`);
            console.log(`🔗 Connect your Moto G 2025 to one of these addresses:`);
            interfaces.forEach(addr => {
                console.log(`   ws://${addr}:${this.port}`);
            });
            console.log('');
        });

        this.server.on('error', (error) => {
            console.error(`❌ Server error: ${error.message}`);
            if (error.code === 'EADDRINUSE') {
                console.log(`💡 Port ${this.port} is already in use. Try a different port or stop the existing service.`);
            }
            process.exit(1);
        });
    }

    initializeCommandLine() {
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            prompt: '🏍️  CVMA Bridge> '
        });

        this.rl.on('line', (input) => {
            this.handleTerminalInput(input.trim());
            this.rl.prompt();
        });

        this.rl.on('close', () => {
            console.log('\n👋 CVMA Bridge shutting down...');
            this.shutdown();
        });

        // Start prompting
        this.rl.prompt();
    }

    handleTerminalInput(input) {
        if (!input) return;

        // Handle prompt command
        if (input.startsWith('prompt:')) {
            const promptText = input.substring(7).trim();
            this.processPrompt(promptText);
            return;
        }

        // Handle other commands
        switch (input.toLowerCase()) {
            case 'help':
                this.showHelp();
                break;
            case 'status':
                this.showStatus();
                break;
            case 'clear':
                console.clear();
                this.displayWelcome();
                break;
            case 'quit':
            case 'exit':
                this.rl.close();
                break;
            default:
                if (input.startsWith('prompt:')) {
                    // Already handled above
                } else {
                    console.log(`❓ Unknown command: ${input}`);
                    console.log(`💡 Type 'help' for available commands`);
                }
        }
    }

    processPrompt(promptText) {
        if (this.clients.size === 0) {
            console.log('📱 No Android devices connected. Connect your Moto G 2025 first.');
            return;
        }

        // Parse prompt for numbered options
        const options = this.parseOptions(promptText);

        const request = {
            timestamp: Date.now(),
            context: this.extractContext(promptText),
            options: options,
            rawPrompt: promptText
        };

        this.currentRequest = request;

        // Send to all connected clients
        this.broadcastToClients({
            type: 'decision_request',
            data: request
        });

        console.log(`📤 Prompt sent to ${this.clients.size} connected device(s)`);
        console.log(`📱 Check your Moto G 2025 for the decision prompt`);
    }

    parseOptions(promptText) {
        const options = [];
        const lines = promptText.split('\n');

        for (const line of lines) {
            // Match numbered options like "1. Option text" or "1) Option text"
            const match = line.match(/^\s*(\d+)[\.\)]\s*(.+)$/);
            if (match) {
                options.push({
                    number: parseInt(match[1]),
                    text: match[2].trim()
                });
            }
        }

        return options;
    }

    extractContext(promptText) {
        const lines = promptText.split('\n');
        const contextLines = [];

        for (const line of lines) {
            // Skip numbered options and empty lines
            if (!line.match(/^\s*\d+[\.\)]\s*/) && line.trim()) {
                contextLines.push(line.trim());
            }
        }

        return contextLines.join(' ').trim() || 'Choose an option:';
    }

    handleClientMessage(message) {
        switch (message.type) {
            case 'select_option':
                this.handleOptionSelection(message);
                break;
            case 'custom_text':
                this.handleCustomText(message);
                break;
            default:
                console.log(`❓ Unknown message type from client: ${message.type}`);
        }
    }

    handleOptionSelection(message) {
        const optionNumber = message.optionNumber || message.data?.optionNumber;

        console.log('\n🔄 COPY THIS TO YOUR CLAUDE CODE SESSION:');
        console.log('═'.repeat(50));
        console.log(optionNumber);
        console.log('═'.repeat(50));
        console.log('');

        this.currentRequest = null;
    }

    handleCustomText(message) {
        const customText = message.text || message.data?.text;

        console.log('\n🔄 COPY THIS TO YOUR CLAUDE CODE SESSION:');
        console.log('═'.repeat(50));
        console.log(customText);
        console.log('═'.repeat(50));
        console.log('');

        this.currentRequest = null;
    }

    sendToClient(client, data) {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    }

    broadcastToClients(data) {
        this.clients.forEach(client => {
            this.sendToClient(client, data);
        });
    }

    getNetworkInterfaces() {
        const interfaces = os.networkInterfaces();
        const addresses = [];

        for (const name of Object.keys(interfaces)) {
            for (const iface of interfaces[name]) {
                // Skip internal and non-IPv4 addresses
                if (!iface.internal && iface.family === 'IPv4') {
                    addresses.push(iface.address);
                }
            }
        }

        // Add localhost for local testing
        addresses.unshift('localhost');

        return addresses;
    }

    showHelp() {
        console.log(`
🏍️  CVMA Claude Code Bridge - Help

📱 MOBILE CONNECTION:
   Connect your Moto G 2025 to: ws://[YOUR_IP]:${this.port}

🔧 AVAILABLE COMMANDS:
   prompt:TEXT    - Send a prompt with options to your mobile device
   status         - Show connection status
   clear          - Clear the screen
   help           - Show this help message
   quit/exit      - Shutdown the bridge

📋 USAGE EXAMPLE:
   When Claude shows options in your terminal:

   Claude: "1. Continue with current approach
            2. Try different method
            3. Ask for clarification"

   You type: prompt:1. Continue with current approach
             2. Try different method
             3. Ask for clarification

   Your Moto G 2025 receives the options as buttons!

🎯 WORKFLOW:
   1. Start this bridge (node claude_ws_bridge.js)
   2. Connect Android app to the displayed IP address
   3. Copy Claude's prompts using 'prompt:' command
   4. Select option on your Moto G 2025
   5. Copy the response back to Claude Code session
`);
    }

    showStatus() {
        console.log(`
📊 CVMA Bridge Status:
   🌐 Server: Running on port ${this.port}
   📱 Connected devices: ${this.clients.size}
   📋 Current request: ${this.currentRequest ? 'Active' : 'None'}
   🔗 Network interfaces: ${this.getNetworkInterfaces().join(', ')}
`);
    }

    displayWelcome() {
        console.log(`
🏍️ ═══════════════════════════════════════════════════════════════
   CVMA Claude Code WebSocket Bridge - Moto G 2025 Ready
   Combat Veterans Motorcycle Association Chapter 20-7
   "Vets Serving Vets" - Enhanced Development Workflow
═══════════════════════════════════════════════════════════════

📱 Ready for your Motorola Moto G 2025 connection!
💡 Type 'help' for commands or 'prompt:' to send decision requests
🔧 Use 'status' to check connections

`);
    }

    shutdown() {
        if (this.server) {
            this.server.close();
        }
        process.exit(0);
    }
}

// Handle process termination gracefully
process.on('SIGINT', () => {
    console.log('\n👋 Received SIGINT, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n👋 Received SIGTERM, shutting down gracefully...');
    process.exit(0);
});

// Check if ws module is available
try {
    require.resolve('ws');
} catch (error) {
    console.error(`❌ Missing dependency: ws`);
    console.log(`💡 Install it with: npm install ws`);
    console.log(`📦 Or if you prefer: npm install ws readline`);
    process.exit(1);
}

// Start the bridge
console.log('🚀 Starting CVMA Claude Code Bridge...');
const bridge = new ClaudeWebSocketBridge();
