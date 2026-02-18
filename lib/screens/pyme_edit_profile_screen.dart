import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pyme_service.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
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
  late TextEditingController _donationGoalController;
  bool _isLoading = false;
  final PymeService _pymeService = PymeService();
  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  String? _logoUrl;
  String? _coverImageUrl;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.currentData.name);
    _descriptionController = TextEditingController(text: widget.currentData.description ?? '');
    _addressController = TextEditingController(text: widget.currentData.location ?? '');
    _phoneController = TextEditingController(text: widget.currentData.whatsappNumber ?? '');
    _websiteController = TextEditingController(text: widget.currentData.webUrl ?? '');
    _donationGoalController = TextEditingController(text: (widget.currentData.donationGoal ?? 100000).toInt().toString());
    _logoUrl = widget.currentData.logoUrl;
    _coverImageUrl = widget.currentData.coverImageUrl;
    _selectedCategory = widget.currentData.category;
  }

  Future<void> _pickAndUploadImage(bool isCover) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      String? url;
      if (isCover) {
        url = await _storageService.uploadCoverImage(image, userId);
        if (url != null) setState(() => _coverImageUrl = url);
      } else {
        url = await _storageService.uploadProfileImage(image, userId);
        if (url != null) setState(() => _logoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _donationGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Check if category changed
    if (_selectedCategory != widget.currentData.category && widget.currentData.category != null) {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Cambiar Categoría?'),
          content: const Text(
            'Al cambiar la categoría de tu negocio, se eliminarán permanentemente todos tus productos y ofertas actuales, ya que pueden no ser compatibles con la nueva categoría.\n\n¿Deseas continuar?',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cambiar y eliminar datos'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;
    }

    setState(() => _isLoading = true);

    try {
      // Delete products and offers if category changed
      if (_selectedCategory != widget.currentData.category && widget.currentData.category != null) {
         await _productService.deleteAllProductsByPyme(userId);
         await _pymeService.deleteAllOffersByPyme(userId);
      }

      Map<String, dynamic> updates = {
        'name': _companyNameController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'location': _addressController.text,
        'whatsappNumber': _phoneController.text,
        'webUrl': _websiteController.text,
        'logoUrl': _logoUrl,
        'coverImageUrl': _coverImageUrl,
      };

      if (widget.currentData.role == UserRole.foundation) {
        updates['donationGoal'] = double.tryParse(_donationGoalController.text) ?? 100000.0;
      }

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
              _buildImagesSection(),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF2F3F2A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ProductService.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 24),
              _buildTextField('Nombre de la Empresa', _companyNameController, Icons.business),
              const SizedBox(height: 16),
              _buildTextField('Descripción', _descriptionController, Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Dirección', _addressController, Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField('Teléfono', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Sitio Web', _websiteController, Icons.language, keyboardType: TextInputType.url),
              
              if (widget.currentData.role == UserRole.foundation) ...[
                const SizedBox(height: 16),
                _buildTextField('Meta de Recaudación', _donationGoalController, Icons.monetization_on, keyboardType: TextInputType.number),
              ],

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

  Widget _buildImagesSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Cover Image
            GestureDetector(
              onTap: () => _pickAndUploadImage(true),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  image: _coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _coverImageUrl == null
                    ? const Icon(Icons.camera_alt, color: Colors.grey, size: 40)
                    : null,
              ),
            ),
            // Profile Image (Logo)
            Positioned(
              bottom: -40,
              child: GestureDetector(
                onTap: () => _pickAndUploadImage(false),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _logoUrl != null ? NetworkImage(_logoUrl!) : null,
                    child: _logoUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text('Toca las imágenes para editar', 
             style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      ],
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
