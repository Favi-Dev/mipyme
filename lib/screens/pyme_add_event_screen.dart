import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class PymeAddEventScreen extends StatefulWidget {
  const PymeAddEventScreen({super.key});

  @override
  State<PymeAddEventScreen> createState() => _PymeAddEventScreenState();
}

class _PymeAddEventScreenState extends State<PymeAddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final ProductService _productService = ProductService();

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

  void _saveEvent() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      final newEvent = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pymeId: 'pyme1',
        name: _titleController.text,
        description: _descriptionController.text,
        price: 0, // Events are free or price is irrelevant for this display
        imageUrl: _imageUrlController.text.isNotEmpty 
            ? _imageUrlController.text 
            : 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?auto=format&fit=crop&w=500&q=60',
        code: 'EVT-${DateTime.now().millisecondsSinceEpoch}',
        stock: 100, // Unlimited or high capacity
        category: 'Educación y cultura',
        isService: true,
        customAttributes: {
          'is_event': 'true',
          'event_date': '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          'event_time': '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          'event_location': _locationController.text,
        },
      );

      _productService.addProduct(newEvent);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento creado exitosamente')),
      );
      Navigator.pop(context);
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona fecha y hora')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('Nuevo Evento', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
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
              _buildTextField(
                controller: _imageUrlController,
                label: 'URL de la Imagen (Opcional)',
                icon: Icons.image,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF0056D2)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null 
                                      ? 'Seleccionar' 
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hora', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Color(0xFF0056D2)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null 
                                      ? 'Seleccionar' 
                                      : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                    backgroundColor: const Color(0xFF0056D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Publicar Evento',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
