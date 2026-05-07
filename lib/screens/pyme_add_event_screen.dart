import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';

class PymeAddEventScreen extends StatefulWidget {
  final Product? event;
  final String? pymeId;

  const PymeAddEventScreen({
    super.key, 
    this.event,
    this.pymeId,
  });

  @override
  State<PymeAddEventScreen> createState() => _PymeAddEventScreenState();
}

class _PymeAddEventScreenState extends State<PymeAddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _imageUrl;
  bool _isLoading = false;

  final ProductService _productService = ProductService();
  final PymeService _pymeService = PymeService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.name ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _imageUrl = widget.event?.imageUrl;
    _priceController = TextEditingController(text: widget.event?.price.toStringAsFixed(0) ?? '0');
    _capacityController = TextEditingController(text: (widget.event?.stock ?? 100).toString());
    
    // Parse location and date/time from customAttributes if editing
    _locationController = TextEditingController(
      text: widget.event?.customAttributes['event_location'] ?? ''
    );
    
    if (widget.event != null) {
       final dateStr = widget.event!.customAttributes['event_date'];
       if (dateStr != null) {
         try {
           final parts = dateStr.split('/');
           _selectedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
         } catch (_) {}
       }
       
       final timeStr = widget.event!.customAttributes['event_time'];
       if (timeStr != null) {
         try {
           final parts = timeStr.split(':');
           _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
         } catch (_) {}
       }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 80);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      // Use 'products' folder or 'events' folder? StorageService currently has 'uploadProductImage'
      // which puts it in 'products/$id/'. Since I don't have event ID yet (unless editing), 
      // I might need a temp ID or use "new_event". 
      // But uploadProductImage takes productId.
      
      final tempId = widget.event?.id ?? 'temp_event_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _storageService.uploadProductImage(image, tempId);
      
      if (url != null) {
        setState(() => _imageUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null && _imageUrl != null) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      // If pymeId is provided (Admin mode), use it. Otherwise use current user.
      final targetPymeId = widget.pymeId ?? user?.uid;

      if (targetPymeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final isEditing = widget.event != null;
      final ownerProfile = await _pymeService.getPymeById(targetPymeId);
      final eventCategory = ownerProfile?.category ?? widget.event?.category ?? 'Educacion y cultura';
      final capacity = int.tryParse(_capacityController.text) ?? widget.event?.stock ?? 0;

      final eventData = Product(
        id: isEditing ? widget.event!.id : '', // Keep ID if editing (service handles new ID if empty string but usually creates one)
        pymeId: targetPymeId,
        name: _titleController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0, 
        imageUrl: _imageUrl!,
        code: isEditing ? widget.event!.code : 'EVT-${DateTime.now().millisecondsSinceEpoch}',
        stock: capacity,
        category: eventCategory,
        isService: true, // Events are services technically in this model
        customAttributes: {
          'is_event': 'true',
          'require_registration': 'true',
          'event_date': '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          'event_time': '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          'event_location': _locationController.text,
          'event_capacity': capacity.toString(),
        },
        registeredCount: widget.event?.registeredCount ?? 0,
      );

      if (isEditing) {
        await _productService.updateProduct(eventData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento actualizado exitosamente')),
        );
      } else {
        await _productService.addProduct(eventData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento creado exitosamente')),
        );
      }
      
      setState(() => _isLoading = false);
      Navigator.pop(context);
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona fecha y hora')),
      );
    } else if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor añade una imagen al evento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(widget.event != null ? 'Editar Evento' : 'Nuevo Evento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFFF4F1EA),
        foregroundColor: const Color(0xFF2F3F2A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Título del Evento',
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripción',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Ubicación',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              // Price (Ticket?)
              _buildTextField(
                controller: _priceController,
                label: 'Precio Entrada (0 si es gratis)',
                icon: Icons.attach_money,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _capacityController,
                label: 'Cupos disponibles',
                icon: Icons.people_alt_outlined,
                isNumber: true,
              ),

              const SizedBox(height: 24),
              
              // Image Picker
              GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      image: _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              Text('Añadir Imagen del Evento', style: GoogleFonts.poppins(color: Colors.grey))
                            ],
                          )
                        : Container(
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(8),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.edit, color: Colors.black),
                            ),
                          ),
                  ),
              ),
              if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),

              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6F8F5E)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null 
                                      ? 'Seleccionar' 
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hora', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Color(0xFF6F8F5E)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null 
                                      ? 'Seleccionar' 
                                      : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Publicar Evento',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF4F1EA),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF2F3F2A).withOpacity(0.7)),
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
          borderSide: const BorderSide(color: Color(0xFF6F8F5E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
      ),
    );
  }
}
