import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyBHiwY8g2klbEy26z80UaxzIlqtIT8YQuQ';
  final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + apiKey);
  
  final client = HttpClient();
  final request = await client.postUrl(url);
  request.headers.contentType = ContentType.json;
  
  final body = jsonEncode({
    'email': 'admin@soyplus.cl',
    'password': 'password123',
    'returnSecureToken': true
  });
  
  request.write(body);
  final response = await request.close();
  
  final responseBody = await response.transform(utf8.decoder).join();
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + responseBody);
}
