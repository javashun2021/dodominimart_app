// Non-web stub — SSE not needed on mobile (FCM handles it)
void connectSse(String url, void Function(String event, String data) onEvent) {}
void disconnectSse() {}
