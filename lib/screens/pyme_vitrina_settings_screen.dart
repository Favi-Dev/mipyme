import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/pyme_service.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'terms_of_use_screen.dart';
import 'login_screen.dart';

class PymeVitrinaSettingsScreen extends StatefulWidget {
  final String? pymeId;
  const PymeVitrinaSettingsScreen({super.key, this.pymeId});

  @override
  State<PymeVitrinaSettingsScreen> createState() =>
      _PymeVitrinaSettingsScreenState();
}

class _PymeVitrinaSettingsScreenState extends State<PymeVitrinaSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  // late TextEditingController _hoursController; 
  // late TextEditingController _locationController;
  late TextEditingController _webController;
  late TextEditingController _instagramController;
  late TextEditingController _whatsappController;

  final PymeService _pymeService = PymeService();
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  bool _isUploading = false;
  String? _targetPymeId;
  String? _profileImageUrl;
  String? _coverImageUrl;

  String? _selectedLocation;
  String? _selectedHours;
  String? _selectedCategory;
  String? _originalCategory;
  List<String> _tags = [];

  final List<String> _communes = [
    'Cerrillos', 'Cerro Navia', 'Conchalí', 'El Bosque', 'Estación Central',
    'Huechuraba', 'Independencia', 'La Cisterna', 'La Florida', 'La Granja',
    'La Pintana', 'La Reina', 'Las Condes', 'Lo Barnechea', 'Lo Espejo',
    'Lo Prado', 'Macul', 'Maipú', 'Ñuñoa', 'Pedro Aguirre Cerda', 'Peñalolén',
    'Providencia', 'Pudahuel', 'Quilicura', 'Quinta Normal', 'Recoleta',
    'Renca', 'San Joaquín', 'San Miguel', 'San Ramón', 'Santiago',
    'Vitacura', 'Puente Alto', 'San Bernardo'
  ];

  final List<String> _scheduleOptions = [
    'Lunes a Viernes 09:00 - 18:00',
    'Lunes a Viernes 09:00 - 19:00',
    'Lunes a Sábado 09:00 - 20:00',
    'Lunes a Domingo 09:00 - 21:00',
    'Martes a Domingo 10:00 - 20:00',
    'Siempre Abierto (24/7)',
    'Atención con Cita Previa',
    'Horario Flexible'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    // _hoursController and _locationController are removed/unused for text input now
    // but kept if needed for custom input or migration. 
    // Actually, let's remove them from init and use state string vars.
    _webController = TextEditingController();
    _instagramController = TextEditingController();
    _whatsappController = TextEditingController();
    
    _loadPymeData();
  }

  Future<void> _loadPymeData() async {
    _targetPymeId = widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid;
    
    if (_targetPymeId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userProfile = await _pymeService.getPymeById(_targetPymeId!);
      if (userProfile != null) {
        if (mounted) {
          setState(() {
            _nameController.text = userProfile.name;
            _descriptionController.text = userProfile.description ?? '';
            // Handle new selectable fields
            _selectedLocation = userProfile.location;
            if (_selectedLocation != null && !_communes.contains(_selectedLocation)) {
               // If existing value is not in list, maybe add it or ignore? 
               // Adding it allows legacy values to be shown and changed.
               _communes.add(_selectedLocation!);
            }
            
            _selectedHours = userProfile.hours;
            if (_selectedHours != null && !_scheduleOptions.contains(_selectedHours)) {
               _scheduleOptions.add(_selectedHours!);
            }
            
            _webController.text = userProfile.webUrl ?? '';
            _instagramController.text = userProfile.instagramHandle ?? '';
            _whatsappController.text = userProfile.whatsappNumber ?? '';
            _profileImageUrl = userProfile.logoUrl;
            _coverImageUrl = userProfile.coverImageUrl;
            _selectedCategory = userProfile.category;
            _originalCategory = userProfile.category;
            _tags = List<String>.from(userProfile.tags ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading pyme data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool isCover) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _uploadImage(image, isCover);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage(XFile file, bool isCover) async {
    if (_targetPymeId == null) return;

    setState(() => _isUploading = true);
    
    try {
      final String type = isCover ? 'cover' : 'profile';
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path = 'pyme_images/$_targetPymeId/${type}_$timestamp.jpg';
      
      final Reference ref = FirebaseStorage.instance.ref().child(path);
      
      if (kIsWeb) {
        await ref.putData(
          await file.readAsBytes(), 
          SettableMetadata(contentType: 'image/jpeg')
        );
      } else {
        await ref.putFile(File(file.path));
      }

      final String downloadUrl = await ref.getDownloadURL();
      
      setState(() {
        if (isCover) {
          _coverImageUrl = downloadUrl;
        } else {
          _profileImageUrl = downloadUrl;
        }
      });
      
      // Auto-save the image update
      await _pymeService.updatePymeProfile(_targetPymeId!, {
        isCover ? 'coverImageUrl' : 'logoUrl': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    // _hoursController.dispose();
    // _locationController.dispose();
    _webController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_targetPymeId == null) return;

    setState(() => _isLoading = true);

    // Check for category change
    if (_selectedCategory != _originalCategory && _originalCategory != null) {
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

      if (!confirm) {
        if(mounted) setState(() => _isLoading = false);
        return;
      }
      
      try {
         await _productService.deleteAllProductsByPyme(_targetPymeId!);
         await _pymeService.deleteAllOffersByPyme(_targetPymeId!);
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al eliminar productos: $e')),
           );
         }
         // Continue even if delete fails? Or abort? 
         // Probably continue to at least update info, or abort to avoid inconsistency.
         // Let's abort for safety.
         if (mounted) setState(() => _isLoading = false);
         return;
      }
    }

    try {
      await _pymeService.updatePymeProfile(_targetPymeId!, {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'hours': _selectedHours,
        'location': _selectedLocation,
        'webUrl': _webController.text,
        'instagramHandle': _instagramController.text,
        'whatsappNumber': _whatsappController.text,
        'category': _selectedCategory,
        'tags': _tags,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F1EA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6F8F5E))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        title: Text(
          'Editar Vitrina',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2F3F2A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2F3F2A)),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Guardar',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6F8F5E),
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
            // Images Section
            _buildSectionHeader('Imágenes'),
            Center(
              child: Column(
                children: [
                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.store, size: 50, color: Colors.grey)
                            : null,
                      ),
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6F8F5E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Foto de Perfil', style: GoogleFonts.poppins(fontSize: 12)),
                  
                  const SizedBox(height: 24),
                  
                  // Cover Image
                  GestureDetector(
                    onTap: () => _pickImage(true),
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
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Toca para agregar Portada'),
                                ],
                              ),
                            )
                          : Container(
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black26,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Foto de Portada', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Column(
                    children: [
                      LinearProgressIndicator(color: Color(0xFF6F8F5E)),
                      SizedBox(height: 8),
                      Text('Subiendo imagen...'),
                    ],
                  ),
                ),
              ),

            _buildSectionHeader('Información General'),
            _buildTextField('Nombre del Negocio', _nameController),
            const SizedBox(height: 16),
            _buildTextField('Descripción', _descriptionController, maxLines: 4),
            const SizedBox(height: 24),
            _buildSectionHeader('Detalles Operativos'),
            DropdownButtonFormField<String>(
              initialValue: _selectedHours,
              decoration: InputDecoration(
                labelText: 'Horario de Atención',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6F8F5E)),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
              ),
              items: _scheduleOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedHours = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocation,
              decoration: InputDecoration(
                labelText: 'Ubicación / Comuna',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6F8F5E)),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
              ),
              items: _communes.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _selectedLocation = val),
            ),
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
            const SizedBox(height: 24),

            _buildSectionHeader('Categoría'),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Rubro del Negocio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category, color: Color(0xFF6F8F5E)),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
              ),
              items: ProductService.categories.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const Padding(
               padding: EdgeInsets.only(top: 8, left: 4),
               child: Text(
                 'Nota: Cambiar la categoría eliminará tus productos actuales.',
                 style: TextStyle(color: Colors.grey, fontSize: 12),
               ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Etiquetas'),
            const Text(
              'Agrega hasta 5 etiquetas para que te encuentren más fácil (máx. 15 caracteres).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_tags.length < 5)
              TextField(
                decoration: InputDecoration(
                  hintText: 'Escribe una etiqueta y presiona ENTER',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.tag, color: Colors.grey),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    if (value.length > 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La etiqueta no puede tener más de 15 caracteres')),
                      );
                      return;
                    }
                    if (!_tags.contains(value.trim())) {
                      setState(() {
                        _tags.add(value.trim());
                      });
                    }
                  }
                },
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: const Color(0xFF6F8F5E).withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              )).toList(),
            ),

            const SizedBox(height: 40),
            
            if (widget.pymeId == null)
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
                  icon: const Icon(Icons.logout, color: Color(0xFF8B5A3C)),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Color(0xFF8B5A3C), fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B5A3C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
                    );
                  },
                  icon: Icon(Icons.description, size: 16, color: Colors.grey[700]),
                  label: Text(
                    'Términos y Borrar Cuenta',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ),
              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // _confirmDeleteAccount removed

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF2F3F2A),
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
      style: const TextStyle(color: Color(0xFF2F3F2A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2F3F2A).withOpacity(0.7)) : null,
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6F8F5E)),
        ),
      ),
    );
  }
}