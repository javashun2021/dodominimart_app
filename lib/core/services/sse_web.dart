// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

html.EventSource? _es;

void connectSse(String url, void Function(String event, String data) onEvent) {
  disconnectSse();
  _es = html.EventSource(url);
  _es!.addEventListener('order_status', (event) {
    final e = event as html.MessageEvent;
    onEvent('order_status', e.data?.toString() ?? '');
  });
  _es!.addEventListener('error', (_) {
    // EventSource auto-reconnects on error — no manual handling needed
  });
}

void disconnectSse() {
  _es?.close();
  _es = null;
}
