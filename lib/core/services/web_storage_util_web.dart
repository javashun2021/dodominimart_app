// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void clearLocalStorageKeys(List<String> keys) {
  for (final key in keys) {
    html.window.localStorage.remove(key);
  }
}
