import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../services/pyme_service.dart';
import '../models/user_profile.dart';

class PymeEditProfileScreen extends StatefulWidget {
  final UserProfile currentData;

  const PymeEditProfileScreen({super.key, required this.currentData});

  @override
  State<PymeEditProfileScreen> createState() => _PymeEditProfileScreenState();
}

class _PymeEditProfileScreenState extends State<PymeEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  bool _isLoading = false;
  final PymeService _pymeService = PymeService();

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.currentData.name);
    _descriptionController = TextEditingController(text: widget.currentData.description ?? '');
    _addressController = TextEditingController(text: widget.currentData.location ?? '');
    _phoneController = TextEditingController(text: widget.currentData.whatsappNumber ?? '');
    _websiteController = TextEditingController(text: widget.currentData.webUrl ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      Map<String, dynamic> updates = {
        'name': _companyNameController.text,
        'description': _descriptionController.text,
        'location': _addressController.text,
        'whatsappNumber': _phoneController.text,
        'webUrl': _websiteController.text,
      };

      // Update coordinates if address changed
      if (_addressController.text != widget.currentData.location) {
        try {
          String addressToSearch = _addressController.text;
          if (!addressToSearch.toLowerCase().contains('chile')) {
            addressToSearch += ', Chile';
          }
          List<Location> locations = await locationFromAddress(addressToSearch);
          if (locations.isNotEmpty) {
            updates['latitude'] = locations.first.latitude;
            updates['longitude'] = locations.first.longitude;
          }
        } catch (e) {
          debugPrint('Error geocoding address: $e');
        }
      }

      await _pymeService.updatePymeProfile(userId, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text('Editar Perfil', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('Nombre de la Empresa', _companyNameController, Icons.business),
              const SizedBox(height: 16),
              _buildTextField('Descripción', _descriptionController, Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Dirección', _addressController, Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField('Teléfono', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Sitio Web', _websiteController, Icons.language, keyboardType: TextInputType.url),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Guardar Cambios', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2F3F2A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
