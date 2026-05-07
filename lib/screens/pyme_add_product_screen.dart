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

  // Variant system — color + size selectors
  bool _hasVariants = false;
  List<ProductVariant> _variants = []; // auto-generated from colors × sizes

  // Stock controllers keyed by variant id
  List<Map<String, String>> _variantAxes = [];
  final Map<String, TextEditingController> _axisNameControllers = {};
  final Map<String, TextEditingController> _axisValuesControllers = {};


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

    // Load variants — rebuild color/size chips from existing variantAxes
    if (p.hasVariants) {
      _hasVariants = true;
      _variants = p.variants.map((v) => v.copyWith()).toList();
      _variantAxes = p.variantAxes
          .map((axis) => {
                'name': axis['name'] ?? '',
                'values': axis['values'] ?? '',
              })
          .toList();
      _rebuildAxisControllers();
    }
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
             _dynamicControllers['tiempo_estimado'] = TextEditingController();
          }
        break;
      case 'Alimentos y gastronomía':
        if (!_isService) {
          _dynamicControllers['ingredientes'] = TextEditingController();
          _dynamicControllers['porcion'] = TextEditingController();
          _dynamicControllers['dietetico'] = TextEditingController();
        } else {
          _dynamicControllers['tipo_menu'] = TextEditingController();
          _dynamicControllers['incluye_bebida'] = TextEditingController();
        }
        break;
      case 'Servicios profesionales':
         if (_isService) {
           _dynamicControllers['modalidad'] = TextEditingController();
           _dynamicControllers['duracion'] = TextEditingController();
           _dynamicControllers['profesional_cargo'] = TextEditingController();
         } else {
           // Product: e.g. Contract templates, eBooks
           _dynamicControllers['formato_entregable'] = TextEditingController(); // Digital, Físico
           _dynamicControllers['paginas'] = TextEditingController();
         }
        break;
      case 'Salud, belleza y bienestar':
          if (!_isService) {
            _dynamicControllers['laboratorio'] = TextEditingController();
            _dynamicControllers['receta'] = TextEditingController();
          } else {
             _dynamicControllers['duracion_sesion'] = TextEditingController();
             _dynamicControllers['profesional'] = TextEditingController();
             // Event flags
             _dynamicControllers['is_event'] = TextEditingController(text: 'false');
             _dynamicControllers['event_date'] = TextEditingController();
          }
        break;
      case 'Oficios y manufactura':
        if (!_isService) {
          _dynamicControllers['materiales'] = TextEditingController();
          _dynamicControllers['tiempo_entrega'] = TextEditingController();
          _dynamicControllers['personalizado'] = TextEditingController(text: 'No');
        } else {
          // Service: Repairs, Custom Jobs
          _dynamicControllers['tipo_trabajo'] = TextEditingController();
          _dynamicControllers['visita_domicilio'] = TextEditingController(text: 'No');
          _dynamicControllers['garantia'] = TextEditingController();
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
        if (_isService) {
          _dynamicControllers['tipo_vehiculo'] = TextEditingController();
          _dynamicControllers['capacidad'] = TextEditingController();
          _dynamicControllers['cobertura'] = TextEditingController();
        } else {
          _dynamicControllers['dimensiones'] = TextEditingController();
          _dynamicControllers['peso_maximo'] = TextEditingController();
        }
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
    _descController.dispose();
    for (var c in _dynamicControllers.values) c.dispose();
    for (var c in _axisNameControllers.values) c.dispose();
    for (var c in _axisValuesControllers.values) c.dispose();
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

        final axes = _hasVariants
            ? _variantAxes
                .map((axis) => {
                      'name': (axis['name'] ?? '').trim(),
                      'values': (axis['values'] ?? '').trim(),
                    })
                .where((axis) => axis['name']!.isNotEmpty && axis['values']!.isNotEmpty)
                .toList()
            : <Map<String, String>>[];

        if (_hasVariants && (axes.isEmpty || _variants.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Genera las combinaciones de variantes antes de guardar')),
          );
          return;
        }

        final newProduct = Product(
          id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          pymeId: widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          name: _nameController.text,
          description: _descController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          imageUrl: _imageUrl!,
          code: _codeController.text,
          stock: _hasVariants ? 0 : (int.tryParse(_stockController.text) ?? 0),
          category: _currentCategory,
          isService: widget.isService,
          customAttributes: attributes,
          variantAxes: _hasVariants ? axes : [],
          variants: _hasVariants ? _variants : [],
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

                if (!_hasVariants) ...[
                  const SizedBox(height: 16),
                  _buildTextField(_stockController, _isService ? 'Cupos Disponibles' : 'Stock Disponible', Icons.inventory_2_outlined, isNumber: true),
                ],
              ]),

              // Variant Section (only for products, not services)
              if (!_isService) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Variantes'),
                _buildCard([
                  SwitchListTile(
                    title: Text('Este producto tiene variantes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('Ej: diferentes colores, tallas, etc.', style: GoogleFonts.poppins(fontSize: 12)),
                    value: _hasVariants,
                    activeColor: const Color(0xFF6F8F5E),
                    onChanged: (val) {
                      setState(() {
                        _hasVariants = val;
                        if (!val) {
                          _variantAxes.clear();
                          _variants.clear();
                          _axisNameControllers.values.forEach((c) => c.dispose());
                          _axisValuesControllers.values.forEach((c) => c.dispose());
                          _axisNameControllers.clear();
                          _axisValuesControllers.clear();
                        }
                      });
                    },
                  ),
                  if (_hasVariants) ..._buildVariantSection(),
                ]),
              ],

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
        if (_isService) {
          fields = [
            _buildTextField(_dynamicControllers['tipo_menu']!, 'Tipo de Menú/Servicio', Icons.restaurant),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['incluye_bebida']!, '¿Incluye Bebida?', Icons.local_drink, isRequired: false),
          ];
        } else {
          fields = [
            _buildTextField(_dynamicControllers['ingredientes']!, 'Ingredientes Principales', Icons.restaurant_menu),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['porcion']!, 'Tamaño de Porción', Icons.pie_chart),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['dietetico']!, 'Info Dietética (Vegano, Sin Gluten...)', Icons.eco_outlined),
          ];
        }
        break;
      case 'Servicios profesionales':
        if (_isService) {
           fields = [
            _buildTextField(_dynamicControllers['modalidad']!, 'Modalidad (Online/Presencial)', Icons.laptop_mac),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['duracion']!, 'Duración Estimada (Min / Hs)', Icons.timer_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['profesional_cargo']!, 'Profesional a Cargo', Icons.person_outline),
           ];
        } else {
           fields = [
            _buildTextField(_dynamicControllers['formato_entregable']!, 'Formato del Entregable (PDF, Plantilla...)', Icons.file_present),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['paginas']!, 'Número de Páginas Estimado', Icons.file_copy_outlined, isRequired: false),
           ];
        }
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
        if (!_isService) {
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
        } else {
           fields = [
            _buildTextField(_dynamicControllers['tipo_trabajo']!, 'Tipo de Trabajo (Reparación, Mantención)', Icons.build),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['garantia']!, 'Garantía del Servicio (Ej: 3 meses)', Icons.verified_user_outlined),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('¿Requiere Visita a Domicilio?', style: GoogleFonts.poppins()),
              value: _dynamicControllers['visita_domicilio']?.text == 'Sí',
              activeColor: const Color(0xFF6F8F5E),
              onChanged: (val) {
                setState(() {
                  _dynamicControllers['visita_domicilio']?.text = val ? 'Sí' : 'No';
                });
              },
            ),
           ];
        }
        break;
      case 'Educación y cultura':
        if (_isService) {
           fields = [
            _buildTextField(_dynamicControllers['modalidad']!, 'Modalidad', Icons.laptop_mac),
             const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['duracion']!, 'Duración', Icons.timer_outlined),
             const SizedBox(height: 16),
             SwitchListTile(
              title: Text('¿Entrega Certificado?', style: GoogleFonts.poppins()),
              value: _dynamicControllers['certificado']?.text == 'Sí',
              activeColor: const Color(0xFF6F8F5E),
              onChanged: (val) {
                setState(() {
                  _dynamicControllers['certificado']?.text = val ? 'Sí' : 'No';
                });
              },
            ),
           ];
        } else {
           fields = [
             _buildTextField(_dynamicControllers['nivel']!, 'Nivel (e.g., Básico, Avanzado)', Icons.school_outlined),
             const SizedBox(height: 16),
             _buildTextField(_dynamicControllers['material_incluido']!, 'Material Incluido', Icons.shopping_bag_outlined),
           ];
        }
        break;
      case 'Transporte y logística':
        if (_isService) {
           fields = [
            _buildTextField(_dynamicControllers['tipo_vehiculo']!, 'Tipo de Vehículo', Icons.directions_car),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['capacidad']!, 'Capacidad de Carga / Pasajeros', Icons.local_shipping_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['cobertura']!, 'Zona de Cobertura', Icons.map_outlined),
           ];
        } else {
           fields = [
             _buildTextField(_dynamicControllers['dimensiones']!, 'Dimensiones', Icons.aspect_ratio),
             const SizedBox(height: 16),
             _buildTextField(_dynamicControllers['peso_maximo']!, 'Peso Máximo Permitido', Icons.scale_outlined),
           ];
        }
        break;
      default:
        fields = [Text('Categoría no configurada', style: GoogleFonts.poppins())];
    }
    return fields;
  }

  // ─── Variant Management Methods ───

  List<Widget> _buildVariantSection() {
    return [
      const Divider(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildVariantPresetChip('Color', 'Rojo, Azul, Negro, Blanco'),
          _buildVariantPresetChip('Talla', 'S, M, L, XL'),
          _buildVariantPresetChip('Material', 'Algodon, Lino, Cuero'),
        ],
      ),
      const SizedBox(height: 12),
      // Axis list
      ..._variantAxes.asMap().entries.map((entry) {
        final i = entry.key;
        final key = 'axis_$i';
        _axisNameControllers.putIfAbsent(key, () => TextEditingController(text: _variantAxes[i]['name'] ?? ''));
        _axisValuesControllers.putIfAbsent(key, () => TextEditingController(text: _variantAxes[i]['values'] ?? ''));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _axisNameControllers[key],
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Eje ${i + 1}',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    hintText: 'Color',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (val) {
                    _variantAxes[i]['name'] = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _axisValuesControllers[key],
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Valores (separados por coma)',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    hintText: 'Rojo, Azul, Verde',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (val) {
                    _variantAxes[i]['values'] = val;
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                onPressed: () {
                  setState(() {
                    _variantAxes.removeAt(i);
                    _axisNameControllers.remove(key)?.dispose();
                    _axisValuesControllers.remove(key)?.dispose();
                    // Re-key remaining controllers
                    _rebuildAxisControllers();
                  });
                },
              ),
            ],
          ),
        );
      }),

      // Add axis button
      if (_variantAxes.length < 3)
        TextButton.icon(
          onPressed: () {
            setState(() {
              _addVariantAxis('', '');
            });
          },
          icon: const Icon(Icons.add, color: Color(0xFF6F8F5E)),
          label: Text('Agregar eje de variante', style: GoogleFonts.poppins(color: const Color(0xFF6F8F5E))),
        ),

      const SizedBox(height: 12),

      // Generate button
      if (_variantAxes.isNotEmpty)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _generateVariants,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text('Generar combinaciones', style: GoogleFonts.poppins()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6F8F5E),
              side: const BorderSide(color: Color(0xFF6F8F5E)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

      // Variant grid
      if (_variants.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6F8F5E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6F8F5E).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory, size: 18, color: Color(0xFF6F8F5E)),
              const SizedBox(width: 8),
              Text(
                '${_variants.length} variantes · Stock total: ${_variants.fold<int>(0, (s, v) => s + v.stock)}',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._variants.asMap().entries.map((entry) {
          final idx = entry.key;
          final v = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    v.label,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    initialValue: v.stock.toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      labelStyle: GoogleFonts.poppins(fontSize: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      final current = _variants[idx];
                      _variants[idx] = ProductVariant(
                        id: current.id,
                        attributes: current.attributes,
                        stock: int.tryParse(val) ?? 0,
                        priceOverride: current.priceOverride,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: v.priceOverride?.toStringAsFixed(0) ?? '',
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      labelStyle: GoogleFonts.poppins(fontSize: 10),
                      hintText: 'Base',
                      hintStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) {
                      final current = _variants[idx];
                      _variants[idx] = ProductVariant(
                        id: current.id,
                        attributes: current.attributes,
                        stock: current.stock,
                        priceOverride: val.trim().isEmpty ? null : double.tryParse(val),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ];
  }

  Widget _buildVariantPresetChip(String name, String values) {
    final exists = _variantAxes.any((axis) => (axis['name'] ?? '').toLowerCase() == name.toLowerCase());
    return ActionChip(
      avatar: Icon(exists ? Icons.check : Icons.add, size: 16),
      label: Text(name, style: GoogleFonts.poppins(fontSize: 12)),
      onPressed: exists
          ? null
          : () {
              setState(() {
                _addVariantAxis(name, values);
              });
            },
    );
  }

  void _addVariantAxis(String name, String values) {
    if (_variantAxes.length >= 3) return;
    _variantAxes.add({'name': name, 'values': values});
    _rebuildAxisControllers();
  }

  void _rebuildAxisControllers() {
    final oldNames = Map<String, TextEditingController>.from(_axisNameControllers);
    final oldValues = Map<String, TextEditingController>.from(_axisValuesControllers);
    _axisNameControllers.clear();
    _axisValuesControllers.clear();
    for (int i = 0; i < _variantAxes.length; i++) {
      final key = 'axis_$i';
      _axisNameControllers[key] = TextEditingController(text: _variantAxes[i]['name'] ?? '');
      _axisValuesControllers[key] = TextEditingController(text: _variantAxes[i]['values'] ?? '');
    }
    oldNames.values.forEach((c) => c.dispose());
    oldValues.values.forEach((c) => c.dispose());
  }

  void _generateVariants() {
    // Parse axes
    final List<MapEntry<String, List<String>>> parsedAxes = [];
    for (final axis in _variantAxes) {
      final name = (axis['name'] ?? '').trim();
      final values = (axis['values'] ?? '').split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
      if (name.isNotEmpty && values.isNotEmpty) {
        parsedAxes.add(MapEntry(name, values));
      }
    }

    if (parsedAxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Define al menos un eje con valores')),
      );
      return;
    }

    // Generate cartesian product
    List<Map<String, String>> combos = [{}];
    for (final axis in parsedAxes) {
      final newCombos = <Map<String, String>>[];
      for (final combo in combos) {
        for (final value in axis.value) {
          newCombos.add({...combo, axis.key: value});
        }
      }
      combos = newCombos;
    }

    // Preserve existing stock/price for matching variants
    final oldVariantsMap = {for (var v in _variants) v.id: v};

    setState(() {
      _variants = combos.map((attrs) {
        final id = attrs.entries
            .map((entry) => '${entry.key}_${entry.value}'.toLowerCase().replaceAll(' ', '_'))
            .join('_');
        final existing = oldVariantsMap[id];
        return ProductVariant(
          id: id,
          attributes: attrs,
          stock: existing?.stock ?? 0,
          priceOverride: existing?.priceOverride,
        );
      }).toList();
    });
  }
}
