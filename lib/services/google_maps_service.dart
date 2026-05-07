import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyAIJFLXJMwVjYRNlAkE2nED_OLch5ZmTDw';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<Map<String, dynamic>>> getAutocomplete(String input, {String sessionToken = ''}) async {
    if (input.isEmpty) return [];

    String url = '$_baseUrl/autocomplete/json?input=$input&key=$_apiKey&language=es&components=country:cl&sessiontoken=$sessionToken';
    
    // Add CORS proxy only for web
    if (kIsWeb) {
      url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions'].map((p) => {
            'description': p['description'],
            'placeId': p['place_id'],
            'mainText': p['structured_formatting']['main_text'],
            'secondaryText': p['structured_formatting']['secondary_text'],
          }));
        }
      }
    } catch (e) {
      debugPrint('Error en autocomplete: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, {String sessionToken = ''}) async {
    String url = '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&language=es&sessiontoken=$sessionToken';
    
    if (kIsWeb) {
      url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          if (result['geometry'] != null && result['geometry']['location'] != null) {
            return {
              'address': result['formatted_address'],
              'lat': result['geometry']['location']['lat'],
              'lng': result['geometry']['location']['lng'],
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo detalles del lugar: $e');
    }
    return null;
  }
}
