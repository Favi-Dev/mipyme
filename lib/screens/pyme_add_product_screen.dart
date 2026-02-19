import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../models/product.dart';
import '../models/vitrina_data.dart';
import '../services/product_service.dart';

class PymeAddProductScreen extends StatefulWidget {
  final bool isService;
  final Product? product;
  final String? pymeId;

  const PymeAddProductScreen({super.key, required this.isService, this.product, this.pymeId});

  @override
  State<PymeAddProductScreen> createState() => _PymeAddProductScreenState();
}

class _PymeAddProductScreenState extends State<PymeAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Common Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Removed _imageControllerText in favor of state variable
  String? _imageUrl;
  
  final _descController = TextEditingController();

  // Dynamic Controllers Map
  final Map<String, TextEditingController> _dynamicControllers = {};

  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  late String _currentCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _currentCategory = widget.product!.category;
    } else {
      _currentCategory = VitrinaData.category;
    }
    _initializeDynamicControllers();
    
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final p = widget.product!;
    _nameController.text = p.name;
    _codeController.text = p.code;
    _priceController.text = p.price == 0 && p.customAttributes['allow_quote'] == 'true' ? '' : p.price.toStringAsFixed(0);
    _stockController.text = p.stock.toString();
    _imageUrl = p.imageUrl;
    _descController.text = p.description;

    // Check allow quote
    if (p.customAttributes['allow_quote'] == 'true') {
      _allowQuote = true;
    }
    
    // Load dynamic attributes
    p.customAttributes.forEach((key, value) {
      if (_dynamicControllers.containsKey(key)) {
        _dynamicControllers[key]!.text = value.toString();
      }
    });
  }

  void _initializeDynamicControllers() {
    
    // Always add 'duracion' if it's a service
    if (_isService) {
      _dynamicControllers['duracion'] = TextEditingController();
    }
    
    // Initialize controllers based on category to ensure they exist
    switch (_currentCategory) {
      case 'Comercio/retail':
      case 'Reciclaje Textil': // Handle Metamorfosis category
          if (!_isService) {
            _dynamicControllers['talla'] = TextEditingController();
            _dynamicControllers['color'] = TextEditingController();
            _dynamicControllers['material'] = TextEditingController();
            if (_currentCategory == 'Reciclaje Textil') {
              _dynamicControllers['pieza_unica'] = TextEditingController(text: 'Sí');
            }
          } else {
             _dynamicControllers['tipo_servicio'] = TextEditingController(); 
          }
        break;
      case 'Alimentos y gastronomía':
        if (!_isService) {
          _dynamicControllers['ingredientes'] = TextEditingController();
          _dynamicControllers['porcion'] = TextEditingController();
          _dynamicControllers['dietetico'] = TextEditingController();
        }
        break;
      case 'Servicios profesionales':
         _dynamicControllers['modalidad'] = TextEditingController(); 
        break;
      case 'Salud, belleza y bienestar':
          if (!_isService) {
            _dynamicControllers['laboratorio'] = TextEditingController();
            _dynamicControllers['receta'] = TextEditingController();
          } else {
             _dynamicControllers['duracion_sesion'] = TextEditingController();
             _dynamicControllers['profesional'] = TextEditingController();
          }
        break;
      case 'Oficios y manufactura':
        if (!_isService) {
          _dynamicControllers['materiales'] = TextEditingController();
          _dynamicControllers['tiempo_entrega'] = TextEditingController();
          _dynamicControllers['personalizado'] = TextEditingController(text: 'No');
        }
        break;
      case 'Educación y cultura':
         // Education products (books, kits)
         if (!_isService) {
            _dynamicControllers['nivel'] = TextEditingController();
            _dynamicControllers['material_incluido'] = TextEditingController(); 
         } else {
            _dynamicControllers['modalidad'] = TextEditingController();
            _dynamicControllers['duracion'] = TextEditingController(); // Already added above but ok
            _dynamicControllers['certificado'] = TextEditingController(text: 'No');
         }
        break;
      case 'Transporte y logística':
        _dynamicControllers['tipo_vehiculo'] = TextEditingController();
        _dynamicControllers['capacidad'] = TextEditingController();
        _dynamicControllers['cobertura'] = TextEditingController();
        break;
    }
  }

  bool get _isService => widget.isService;
  bool _allowQuote = false; // Cotizar en vez de comprar

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    // _imageController.dispose(); // Removed
    _descController.dispose();
    for (var controller in _dynamicControllers.values) {
      controller.dispose();
    }
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
      
      final url = await _storageService.uploadProductImage(image, userId);
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes seleccionar una imagen para el producto')));
        return;
      }
      
      setState(() => _isLoading = true);

      try {
        // Collect dynamic attributes
        Map<String, dynamic> attributes = {};
        _dynamicControllers.forEach((key, controller) {
          if (controller.text.isNotEmpty) {
            attributes[key] = controller.text;
          }
        });

        // Add allowQuote flag to attributes
        if (_allowQuote) {
          attributes['allow_quote'] = 'true';
        }

        final newProduct = Product(
          id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          pymeId: widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          name: _nameController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          imageUrl: _imageUrl!,
          code: _codeController.text,
          stock: int.tryParse(_stockController.text) ?? 0,
          category: _currentCategory,
          isService: widget.isService,
          customAttributes: attributes,
        );

        if (widget.product != null) {
          await _productService.updateProduct(newProduct);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Actualizado en $_currentCategory exitosamente', style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA))),
                backgroundColor: const Color(0xFF2F3F2A),
              ),
            );
          }
        } else {
          await _productService.addProduct(newProduct);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Producto agregado a $_currentCategory exitosamente', style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA))),
                backgroundColor: const Color(0xFF2F3F2A),
              ),
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text('Agregar $_currentCategory', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFF4F1EA))),
        backgroundColor: const Color(0xFF2F3F2A),
        iconTheme: const IconThemeData(color: Color(0xFFF4F1EA)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información General'),
              _buildCard([
                _buildTextField(_nameController, 'Nombre', Icons.label_outline),
                const SizedBox(height: 16),
                _buildTextField(_descController, 'Descripción', Icons.description_outlined, maxLines: 5),
                const SizedBox(height: 16),
                
                // Price Section
                if (_isService) ...[
                  SwitchListTile(
                    title: Text('Opción de cotizar', style: GoogleFonts.poppins()),
                    subtitle: Text('Si se activa, el precio no se mostrará y el cliente solicitará cotización.', style: GoogleFonts.poppins(fontSize: 12)),
                    value: _allowQuote,
                    activeColor: const Color(0xFF6F8F5E),
                    onChanged: (val) {
                      setState(() {
                         _allowQuote = val;
                         if (val) _priceController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                if (!_allowQuote) ...[
                   Row(
                    children: [
                      Expanded(child: _buildTextField(_priceController, 'Precio', Icons.attach_money, isNumber: true, isRequired: !_allowQuote)),
                      const SizedBox(width: 16),
                      if (!_isService) // Only products really need SKU exposed, but kept for legacy
                        Expanded(child: _buildTextField(_codeController, 'Código (SKU)', Icons.qr_code, isRequired: true))
                       else
                        Expanded(child: _buildTextField(_codeController, 'Código', Icons.qr_code, isRequired: false)),
                    ],
                  ),
                ] else ...[
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFF6F8F5E).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.info_outline, color: Color(0xFF6F8F5E)),
                         const SizedBox(width: 8),
                         Expanded(child: Text('Los clientes verán un botón de "Cotizar" en lugar del precio.', style: GoogleFonts.poppins(fontSize: 12))),
                       ],
                     ),
                   ),
                   // Hidden SKU field just in case
                   const SizedBox(height: 8), 
                   _buildTextField(_codeController, 'Código Interno', Icons.qr_code, isRequired: false),
                ],

                const SizedBox(height: 16),
                _buildTextField(_stockController, _isService ? 'Cupos Disponibles' : 'Stock Disponible', Icons.inventory_2_outlined, isNumber: true),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Detalles Específicos'),
              _buildCard(_buildCategorySpecificFields()),

              const SizedBox(height: 24),
              _buildSectionTitle('Multimedia'),
              _buildCard([
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
                              Text('Añadir Imagen', style: GoogleFonts.poppins(color: Colors.grey))
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
              ]),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text('Guardar Producto', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF4F1EA))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*
  String _getStockLabel() {
    if (_isService) {
      return 'Cupos / Disponibilidad';
    }
    return 'Stock Disponible';
  }
*/
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF4F1EA)),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2F3F2A).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
    {bool isNumber = false, int maxLines = 1, bool isRequired = true, int? maxLength}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF6F8F5E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6F8F5E))),
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Campo requerido';
        }
        if (isNumber && value != null && value.isNotEmpty) {
           // final number = double.tryParse(value);
           // Removed explicit upper limit check as per request
        }
        return null;
      },
    );
  }

  List<Widget> _buildCategorySpecificFields() {
    List<Widget> fields = [];
    
    switch (_currentCategory) {
      case 'Comercio/retail':
      case 'Reciclaje Textil':
        if (_isService) {
          fields = [
            _buildTextField(_dynamicControllers['tipo_servicio']!, 'Tipo de Servicio (Ej: Reparación)', Icons.build_circle_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['tiempo_estimado']!, 'Tiempo Estimado', Icons.timer_outlined),
          ];
        } else {
          fields = [
            _buildTextField(_dynamicControllers['talla']!, 'Talla / Medida', Icons.straighten, isRequired: false),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['color']!, 'Color', Icons.palette_outlined, isRequired: false),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['material']!, 'Material', Icons.layers_outlined, isRequired: false),
            if (_currentCategory == 'Reciclaje Textil') ...[
              const SizedBox(height: 16),
              _buildTextField(_dynamicControllers['pieza_unica']!, '¿Es Pieza Única?', Icons.star_border),
            ]
          ];
        }
        break;
      case 'Alimentos y gastronomía':
        fields = [
          _buildTextField(_dynamicControllers['ingredientes']!, 'Ingredientes Principales', Icons.restaurant_menu),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['porcion']!, 'Tamaño de Porción', Icons.pie_chart),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['dietetico']!, 'Info Dietética (Vegano, Sin Gluten...)', Icons.eco_outlined),
        ];
        break;
      case 'Servicios profesionales':
        fields = [
          _buildTextField(_dynamicControllers['modalidad']!, 'Modalidad (Online/Presencial)', Icons.laptop_mac),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['duracion']!, 'Duración Estimada', Icons.timer_outlined),
        ];
        break;
      case 'Salud, belleza y bienestar':
        if (_isService) {
          fields = [
            _buildTextField(_dynamicControllers['duracion_sesion']!, 'Duración de Sesión', Icons.timer),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['profesional']!, 'Profesional a Cargo', Icons.person_outline),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('¿Es un Operativo / Evento Único?', style: GoogleFonts.poppins()),
              subtitle: Text('Activa esto si es una fecha específica', style: GoogleFonts.poppins(fontSize: 12)),
              value: _dynamicControllers['is_event']?.text == 'true',
              activeThumbColor: const Color(0xFF6F8F5E),
              onChanged: (val) {
                setState(() {
                  _dynamicControllers['is_event']?.text = val.toString();
                  if (!val) {
                    _dynamicControllers['event_date']?.clear();
                  }
                });
              },
            ),
            if (_dynamicControllers['is_event']?.text == 'true') ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dynamicControllers['event_date']?.text = date.toIso8601String();
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildTextField(
                    TextEditingController(
                      text: _dynamicControllers['event_date']?.text.split('T').first ?? ''
                    ), 
                    'Fecha del Operativo', 
                    Icons.calendar_month,
                    isRequired: true
                  ),
                ),
              ),
            ],
          ];
        } else {
          fields = [
            _buildTextField(_dynamicControllers['laboratorio']!, 'Laboratorio / Marca', Icons.science_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['receta']!, '¿Requiere Receta? (Sí/No)', Icons.assignment_outlined),
          ];
        }
        break;
      case 'Oficios y manufactura':
        fields = [
          _buildTextField(_dynamicControllers['materiales']!, 'Materiales', Icons.build_circle_outlined),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['tiempo_entrega']!, 'Tiempo de Elaboración/Entrega', Icons.schedule_send),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('¿Es Personalizado?', style: GoogleFonts.poppins()),
            value: _dynamicControllers['personalizado']?.text == 'Sí',
            activeThumbColor: const Color(0xFF6F8F5E),
            onChanged: (val) {
              setState(() {
                _dynamicControllers['personalizado']?.text = val ? 'Sí' : 'No';
              });
            },
          ),
        ];
        break;
      case 'Educación y cultura':
        fields = [
          _buildTextField(_dynamicControllers['nivel']!, 'Nivel (e.g., Básico, Avanzado)', Icons.school_outlined),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['modalidad']!, 'Modalidad (Online / Presencial)', Icons.laptop_mac),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['duracion']!, 'Duración', Icons.timer_outlined),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('¿Incluye Certificado?', style: GoogleFonts.poppins()),
            value: _dynamicControllers['certificado']?.text == 'Sí',
            activeThumbColor: const Color(0xFF6F8F5E),
            onChanged: (val) {
              setState(() {
                _dynamicControllers['certificado']?.text = val ? 'Sí' : 'No';
              });
            },
          ),
        ];
        break;
      case 'Transporte y logística':
        fields = [
          _buildTextField(_dynamicControllers['tipo_vehiculo']!, 'Tipo de Vehículo', Icons.directions_car),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['capacidad']!, 'Capacidad de Carga / Pasajeros', Icons.local_shipping_outlined),
          const SizedBox(height: 16),
          _buildTextField(_dynamicControllers['cobertura']!, 'Zona de Cobertura', Icons.map_outlined),
        ];
        break;
      default:
        fields = [Text('Categoría no configurada', style: GoogleFonts.poppins())];
    }
    return fields;
  }
}
