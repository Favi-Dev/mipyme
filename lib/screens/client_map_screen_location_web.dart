import 'package:flutter/foundation.dart';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation: uses the browser's Geolocation API directly.
Future<Map<String, double>?> getCurrentLocation() async {
  final completer = Completer<Map<String, double>?>();

  html.window.navigator.geolocation.getCurrentPosition().then((position) {
    completer.complete({
      'lat': position.coords!.latitude! as double,
      'lng': position.coords!.longitude! as double,
    });
  }).catchError((error) {
    debugPrint('Geolocation error on web: $error');
    completer.complete(null);
  });

  return completer.future;
}
