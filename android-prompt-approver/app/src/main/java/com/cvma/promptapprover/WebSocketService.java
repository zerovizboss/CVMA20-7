package com.cvma.promptapprover;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.concurrent.TimeUnit;

public class WebSocketService extends Service {
    private static final String TAG = "WebSocketService";
    private static final String CHANNEL_ID = "CVMAPromptApproverChannel";
    private static final int NOTIFICATION_ID = 1;

    private WebSocketClient webSocketClient;
    private final IBinder binder = new LocalBinder();
    private WebSocketListener listener;
    private Gson gson = new Gson();
    private boolean isConnecting = false;

    public interface WebSocketListener {
        void onConnected();
        void onDisconnected();
        void onDecisionRequest(DecisionRequest request);
        void onConnectionError(String error);
    }

    public class LocalBinder extends Binder {
        WebSocketService getService() {
            return WebSocketService.this;
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, createNotification("Starting connection..."));
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    public void setListener(WebSocketListener listener) {
        this.listener = listener;
    }

    public void connectToServer(String serverAddress) {
        if (isConnecting || (webSocketClient != null && webSocketClient.isOpen())) {
            Log.d(TAG, "Already connecting or connected");
            return;
        }

        try {
            isConnecting = true;
            URI serverUri = new URI(serverAddress);

            webSocketClient = new WebSocketClient(serverUri) {
                @Override
                public void onOpen(ServerHandshake handshake) {
                    Log.d(TAG, "Connected to Claude bridge");
                    isConnecting = false;
                    updateNotification("Connected to Claude Bridge");

                    if (listener != null) {
                        listener.onConnected();
                    }
                }

                @Override
                public void onMessage(String message) {
                    Log.d(TAG, "Received message: " + message);
                    handleIncomingMessage(message);
                }

                @Override
                public void onClose(int code, String reason, boolean remote) {
                    Log.d(TAG, "Connection closed: " + reason);
                    isConnecting = false;
                    updateNotification("Disconnected from Claude Bridge");

                    if (listener != null) {
                        listener.onDisconnected();
                    }

                    // Try to reconnect after delay
                    scheduleReconnect();
                }

                @Override
                public void onError(Exception ex) {
                    Log.e(TAG, "WebSocket error", ex);
                    isConnecting = false;
                    updateNotification("Connection error");

                    if (listener != null) {
                        listener.onConnectionError(ex.getMessage());
                    }
                }
            };

            webSocketClient.setConnectionLostTimeout(30);
            webSocketClient.connect();

        } catch (URISyntaxException e) {
            Log.e(TAG, "Invalid server URI", e);
            isConnecting = false;
            if (listener != null) {
                listener.onConnectionError("Invalid server address");
            }
        }
    }

    private void handleIncomingMessage(String message) {
        try {
            WebSocketMessage wsMessage = gson.fromJson(message, WebSocketMessage.class);

            if ("decision_request".equals(wsMessage.type)) {
                DecisionRequest request = gson.fromJson(gson.toJson(wsMessage.data), DecisionRequest.class);

                if (listener != null) {
                    listener.onDecisionRequest(request);
                }
            }

        } catch (JsonSyntaxException e) {
            Log.e(TAG, "Error parsing message", e);
        }
    }

    public void sendResponse(String type, Object data) {
        if (webSocketClient != null && webSocketClient.isOpen()) {
            try {
                WebSocketMessage message = new WebSocketMessage();
                message.type = type;
                message.data = data;

                String json = gson.toJson(message);
                webSocketClient.send(json);

                Log.d(TAG, "Sent response: " + json);

            } catch (Exception e) {
                Log.e(TAG, "Error sending response", e);
            }
        }
    }

    public void sendOptionSelection(int optionNumber) {
        OptionSelection selection = new OptionSelection();
        selection.optionNumber = optionNumber;
        sendResponse("select_option", selection);
    }

    public void sendCustomText(String text) {
        CustomTextResponse response = new CustomTextResponse();
        response.text = text;
        sendResponse("custom_text", response);
    }

    public boolean isConnected() {
        return webSocketClient != null && webSocketClient.isOpen();
    }

    public void disconnect() {
        if (webSocketClient != null) {
            webSocketClient.close();
        }
    }

    private void scheduleReconnect() {
        new Thread(() -> {
            try {
                Thread.sleep(5000); // Wait 5 seconds before reconnect
                if (!isConnected() && !isConnecting) {
                    // Try to reconnect with last known address
                    // This would need to be stored in SharedPreferences
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }).start();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "CVMA Prompt Approver",
                    NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Claude Code Prompt Approval Service");

            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }

    private Notification createNotification(String content) {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, notificationIntent,
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ?
                        PendingIntent.FLAG_IMMUTABLE : PendingIntent.FLAG_UPDATE_CURRENT
        );

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("CVMA Prompt Approver")
                .setContentText(content)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build();
    }

    private void updateNotification(String content) {
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        manager.notify(NOTIFICATION_ID, createNotification(content));
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (webSocketClient != null) {
            webSocketClient.close();
        }
    }

    // Data classes for JSON parsing
    public static class WebSocketMessage {
        public String type;
        public Object data;
    }

    public static class OptionSelection {
        public int optionNumber;
    }

    public static class CustomTextResponse {
        public String text;
    }
}