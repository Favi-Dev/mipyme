import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/pyme_service.dart';

import '../services/product_service.dart';
import '../widgets/address_autocomplete_field.dart';
import 'terms_of_use_screen.dart';
import 'package:go_router/go_router.dart';

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
  late TextEditingController _addressController; // Changed from _selectedLocation
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

  double? _latitude;
  double? _longitude;

  // Schedule State
  final List<String> _daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  final Map<String, bool> _isOpen = {};
  final Map<String, TimeOfDay> _openTime = {};
  final Map<String, TimeOfDay> _closeTime = {};

  String? _selectedCategory;
  String? _originalCategory;
  List<String> _tags = [];

  // Locations removed as we now use free text input
  // Schedule options removed as we use custom switches

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _webController = TextEditingController();
    _instagramController = TextEditingController();
    _whatsappController = TextEditingController();
    
    // Initialize schedule defaults
    for (var day in _daysOfWeek) {
      _isOpen[day] = true;
      _openTime[day] = const TimeOfDay(hour: 9, minute: 0);
      _closeTime[day] = const TimeOfDay(hour: 18, minute: 0);
    }
    
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
            
            // Handle Address
            _addressController.text = userProfile.location ?? '';
            _latitude = userProfile.latitude;
            _longitude = userProfile.longitude;
            
            // Handle Schedule
            if (userProfile.hours != null && userProfile.hours!.isNotEmpty) {
              final lines = userProfile.hours!.split('\n');
              for (var line in lines) {
                final parts = line.split(': ');
                if (parts.length == 2) {
                  final day = parts[0].trim();
                  final timeRange = parts[1].trim();
                  
                  if (_daysOfWeek.contains(day)) {
                    if (timeRange == 'Cerrado') {
                      _isOpen[day] = false;
                    } else {
                      final times = timeRange.split(' - ');
                      if (times.length == 2) {
                        final openParts = times[0].split(':');
                        final closeParts = times[1].split(':');
                        if (openParts.length == 2 && closeParts.length == 2) {
                          _isOpen[day] = true;
                          _openTime[day] = TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));
                          _closeTime[day] = TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1]));
                        }
                      }
                    }
                  }
                }
              }
            } else {
              // Default initialization already done in initState
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
      // Format Schedule
      String formattedSchedule = '';
      for (var day in _daysOfWeek) {
        if (_isOpen[day] == true) {
           // We use context safely because we are in a state method
           // but format(context) depends on localization. 
           // It's safer to format manually if context might be unstable, 
           // but here context is valid.
           final open = _openTime[day]!;
           final close = _closeTime[day]!;
           final openStr = '${open.hour.toString().padLeft(2,'0')}:${open.minute.toString().padLeft(2,'0')}';
           final closeStr = '${close.hour.toString().padLeft(2,'0')}:${close.minute.toString().padLeft(2,'0')}';
           formattedSchedule += '$day: $openStr - $closeStr\n';
        } else {
           formattedSchedule += '$day: Cerrado\n';
        }
      }

      await _pymeService.updatePymeProfile(_targetPymeId!, {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'hours': formattedSchedule.trim(), // Save the formatted string
        'location': _addressController.text, // Save the manual address
        'latitude': _latitude,
        'longitude': _longitude,
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
            
            // Address Field
            AddressAutocompleteField(
              controller: _addressController,
              labelText: 'Dirección del Local (Autocompletado)',
              onPlaceSelected: (address, lat, lng) {
                debugPrint('Lugar seleccionado: $address ($lat, $lng)');
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Schedule Section
            const Text(
              'Horario de Atención',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2F3F2A)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: _daysOfWeek.map((day) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Switch(
                          value: _isOpen[day] ?? false,
                          activeColor: const Color(0xFF6F8F5E),
                          onChanged: (val) => setState(() => _isOpen[day] = val),
                        ),
                        if (_isOpen[day] == true) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildTimePickerButton(day, true),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('-'),
                                ),
                                _buildTimePickerButton(day, false),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Spacer(),
                          Text(
                            'Cerrado',
                            style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Cerrar Sesión?'),
                        content: const Text('¿Estás seguro de que deseas cerrar tu sesión en la aplicación?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5A3C),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sí, salir'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
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

  Widget _buildTimePickerButton(String day, bool isOpenTime) {
    final TimeOfDay? time = isOpenTime ? _openTime[day] : _closeTime[day];
    
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6F8F5E), // Header background color
                  onPrimary: Colors.white, // Header text color
                  onSurface: Color(0xFF2F3F2A), // Body text color
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            if (isOpenTime) {
              _openTime[day] = picked;
            } else {
              _closeTime[day] = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time?.format(context) ?? '--:--',
          style: const TextStyle(fontSize: 14),
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