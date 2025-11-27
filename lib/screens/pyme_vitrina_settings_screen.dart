import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vitrina_data.dart';
import 'login_screen.dart';

class PymeVitrinaSettingsScreen extends StatefulWidget {
  const PymeVitrinaSettingsScreen({super.key});

  @override
  State<PymeVitrinaSettingsScreen> createState() =>
      _PymeVitrinaSettingsScreenState();
}

class _PymeVitrinaSettingsScreenState extends State<PymeVitrinaSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _hoursController;
  late TextEditingController _locationController;
  late TextEditingController _webController;
  late TextEditingController _instagramController;
  late TextEditingController _whatsappController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: VitrinaData.name);
    _descriptionController =
        TextEditingController(text: VitrinaData.description);
    _hoursController = TextEditingController(text: VitrinaData.hours);
    _locationController = TextEditingController(text: VitrinaData.location);
    _webController = TextEditingController(text: VitrinaData.webUrl);
    _instagramController =
        TextEditingController(text: VitrinaData.instagramHandle);
    _whatsappController =
        TextEditingController(text: VitrinaData.whatsappNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _locationController.dispose();
    _webController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() {
      VitrinaData.name = _nameController.text;
      VitrinaData.description = _descriptionController.text;
      VitrinaData.hours = _hoursController.text;
      VitrinaData.location = _locationController.text;
      VitrinaData.webUrl = _webController.text;
      VitrinaData.instagramHandle = _instagramController.text;
      VitrinaData.whatsappNumber = _whatsappController.text;
    });
    Navigator.pop(context, true); // Return true to indicate changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Editar Vitrina',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Guardar',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Información General'),
            _buildTextField('Nombre del Negocio', _nameController),
            const SizedBox(height: 16),
            _buildTextField('Descripción', _descriptionController, maxLines: 4),
            const SizedBox(height: 24),
            _buildSectionHeader('Detalles Operativos'),
            _buildTextField('Horarios', _hoursController, maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField('Ubicación', _locationController),
            const SizedBox(height: 24),
            _buildSectionHeader('Contacto'),
            _buildTextField('Sitio Web', _webController,
                icon: Icons.language),
            const SizedBox(height: 16),
            _buildTextField('Instagram', _instagramController,
                icon: Icons.camera_alt),
            const SizedBox(height: 16),
            _buildTextField('WhatsApp', _whatsappController,
                icon: Icons.message),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFFFF6B6B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, IconData? icon}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
    );
  }
}
