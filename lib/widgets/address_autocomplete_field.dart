import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../services/google_maps_service.dart';

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(String address, double lat, double lng)? onPlaceSelected;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Dirección Comercial (Recomendado buscar lugar)',
    this.onPlaceSelected,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final Uuid _uuid = const Uuid();
  
  String _sessionToken = '';
  List<Map<String, dynamic>> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = widget.controller.text;
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    // Only search if user is actively typing (not programmatically set)
    if (!FocusScope.of(context).hasFocus) return;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      final results = await _mapsService.getAutocomplete(query, sessionToken: _sessionToken);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleSelection(Map<String, dynamic> prediction) async {
    // Clear predictions list to close dropdown
    setState(() => _predictions = []);
    FocusScope.of(context).unfocus(); // Close keyboard
    
    final placeId = prediction['placeId'];
    if (placeId != null) {
      final details = await _mapsService.getPlaceDetails(placeId, sessionToken: _sessionToken);
      if (details != null && mounted) {
        // Update text with full address
        widget.controller.text = details['address'];
        
        // Notify parent
        if (widget.onPlaceSelected != null) {
          widget.onPlaceSelected!(
            details['address'], 
            details['lat'], 
            details['lng']
          );
        }
        
        // Generate new session token for next search
        _sessionToken = _uuid.v4();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: 'Ej. Av. Providencia 1234',
            labelStyle: GoogleFonts.poppins(color: const Color(0xFF6F8F5E)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF6F8F5E)),
            suffixIcon: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16, height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    ),
                  )
                : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() => _predictions = []);
                      },
                    )
                  : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6F8F5E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6F8F5E), width: 2),
            ),
          ),
        ),
        
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Constraint maximum height for dropdown
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.place, color: Colors.grey),
                  title: Text(
                    prediction['mainText'] ?? '',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: Text(
                    prediction['secondaryText'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () => _handleSelection(prediction),
                );
              },
            ),
          ),
      ],
    );
  }
}
