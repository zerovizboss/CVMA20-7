package com.cvma.promptapprover;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.IBinder;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.textfield.TextInputEditText;

public class MainActivity extends AppCompatActivity implements WebSocketService.WebSocketListener {

    private WebSocketService webSocketService;
    private boolean serviceBound = false;

    // UI Elements
    private TextView connectionStatus;
    private Button connectButton;
    private TextInputEditText serverAddressInput;
    private View decisionPanel;
    private View waitingPanel;
    private TextView contextText;
    private LinearLayout optionsContainer;
    private TextInputEditText customResponseInput;
    private Button sendCustomButton;

    private SharedPreferences prefs;
    private DecisionRequest currentRequest;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initializeViews();
        initializePreferences();
        setupListeners();

        // Bind to WebSocket service
        Intent serviceIntent = new Intent(this, WebSocketService.class);
        startService(serviceIntent);
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    private void initializeViews() {
        connectionStatus = findViewById(R.id.connection_status);
        connectButton = findViewById(R.id.connect_button);
        serverAddressInput = findViewById(R.id.server_address);
        decisionPanel = findViewById(R.id.decision_panel);
        waitingPanel = findViewById(R.id.waiting_panel);
        contextText = findViewById(R.id.context_text);
        optionsContainer = findViewById(R.id.options_container);
        customResponseInput = findViewById(R.id.custom_response);
        sendCustomButton = findViewById(R.id.send_custom_button);

        showWaitingPanel();
    }

    private void initializePreferences() {
        prefs = getSharedPreferences("CVMAPromptApprover", MODE_PRIVATE);
        String savedAddress = prefs.getString("server_address", "ws://192.168.1.100:8080");
        serverAddressInput.setText(savedAddress);
    }

    private void setupListeners() {
        connectButton.setOnClickListener(v -> {
            if (webSocketService != null) {
                if (webSocketService.isConnected()) {
                    webSocketService.disconnect();
                } else {
                    connectToServer();
                }
            }
        });

        sendCustomButton.setOnClickListener(v -> {
            String customText = customResponseInput.getText().toString().trim();
            if (!TextUtils.isEmpty(customText) && webSocketService != null) {
                webSocketService.sendCustomText(customText);
                customResponseInput.setText("");
                showWaitingPanel();
                Toast.makeText(this, "Custom response sent", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void connectToServer() {
        String address = serverAddressInput.getText().toString().trim();
        if (TextUtils.isEmpty(address)) {
            Toast.makeText(this, "Please enter server address", Toast.LENGTH_SHORT).show();
            return;
        }

        // Save address
        prefs.edit().putString("server_address", address).apply();

        if (webSocketService != null) {
            webSocketService.connectToServer(address);
            updateConnectionUI(false, "Connecting...");
        }
    }

    private void showWaitingPanel() {
        waitingPanel.setVisibility(View.VISIBLE);
        decisionPanel.setVisibility(View.GONE);
        currentRequest = null;
    }

    private void showDecisionPanel(DecisionRequest request) {
        currentRequest = request;
        contextText.setText(request.context);

        // Clear previous options
        optionsContainer.removeAllViews();

        // Add option buttons
        if (request.options != null) {
            for (DecisionRequest.Option option : request.options) {
                Button optionButton = createOptionButton(option);
                optionsContainer.addView(optionButton);
            }
        }

        waitingPanel.setVisibility(View.GONE);
        decisionPanel.setVisibility(View.VISIBLE);
    }

    private Button createOptionButton(DecisionRequest.Option option) {
        Button button = (Button) LayoutInflater.from(this)
                .inflate(R.layout.option_button, optionsContainer, false);

        button.setText(option.number + ". " + option.text);
        button.setOnClickListener(v -> {
            if (webSocketService != null) {
                webSocketService.sendOptionSelection(option.number);
                showWaitingPanel();
                Toast.makeText(this, "Option " + option.number + " selected", Toast.LENGTH_SHORT).show();
            }
        });

        return button;
    }

    private void updateConnectionUI(boolean connected, String status) {
        connectionStatus.setText(status);
        connectionStatus.setTextColor(getResources().getColor(
                connected ? R.color.connected : R.color.disconnected));
        connectButton.setText(connected ? "Disconnect" : "Connect");
    }

    // WebSocket Listener Implementation
    @Override
    public void onConnected() {
        runOnUiThread(() -> {
            updateConnectionUI(true, "Connected");
            showWaitingPanel();
            Toast.makeText(this, "Connected to Claude bridge!", Toast.LENGTH_SHORT).show();
        });
    }

    @Override
    public void onDisconnected() {
        runOnUiThread(() -> {
            updateConnectionUI(false, "Disconnected");
            showWaitingPanel();
        });
    }

    @Override
    public void onDecisionRequest(DecisionRequest request) {
        runOnUiThread(() -> {
            showDecisionPanel(request);
            Toast.makeText(this, "New prompt received!", Toast.LENGTH_SHORT).show();
        });
    }

    @Override
    public void onConnectionError(String error) {
        runOnUiThread(() -> {
            updateConnectionUI(false, "Error: " + error);
            Toast.makeText(this, "Connection error: " + error, Toast.LENGTH_LONG).show();
        });
    }

    // Service Connection
    private final ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            WebSocketService.LocalBinder binder = (WebSocketService.LocalBinder) service;
            webSocketService = binder.getService();
            webSocketService.setListener(MainActivity.this);
            serviceBound = true;

            // Update UI based on current connection state
            if (webSocketService.isConnected()) {
                updateConnectionUI(true, "Connected");
                showWaitingPanel();
            } else {
                updateConnectionUI(false, "Disconnected");
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            webSocketService = null;
            serviceBound = false;
        }
    };

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (serviceBound) {
            unbindService(serviceConnection);
            serviceBound = false;
        }
    }
}