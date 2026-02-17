import 'package:flutter/services.dart';

// Formatter for RUT (XX.XXX.XXX-X)
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    
    // Remove formatting characters to get raw value
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Basic length limit (RUT usually max 9 digits including dv without formatting)
    if (newText.length > 9) {
      newText = newText.substring(0, 9);
    }
    
    String rawRut = newText.substring(0, newText.length - 1);
    String dv = newText.substring(newText.length - 1);
    
    // Format the number part with dots
    String result = '';
    int count = 0;
    for (int i = rawRut.length - 1; i >= 0; i--) {
      result = rawRut[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    
    // Add DV with hyphen
    if (result.isNotEmpty) {
      result = '$result-$dv';
    } else {
      result = dv;
    }
    
    return TextEditingValue(
      text: result,
      selection: TextSelection.fromPosition(TextPosition(offset: result.length)),
    );
  }
}
