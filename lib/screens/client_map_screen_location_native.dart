import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Native (Android/iOS) implementation: uses geolocator + permission_handler.
Future<Map<String, double>?> getCurrentLocation() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
  }

  if (status.isGranted) {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (e) {
      debugPrint('Error getting native location: $e');
      return null;
    }
  }
  return null;
}
