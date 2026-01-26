import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _imageController = TextEditingController();
  final _descController = TextEditingController();

  // Dynamic Controllers Map
  final Map<String, TextEditingController> _dynamicControllers = {};

  final ProductService _productService = ProductService();
  late String _currentCategory;

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
    _priceController.text = p.price.toStringAsFixed(0);
    _stockController.text = p.stock.toString();
    _imageController.text = p.imageUrl;
    _descController.text = p.description;
    
    // Load dynamic attributes
    p.customAttributes.forEach((key, value) {
      if (_dynamicControllers.containsKey(key)) {
        _dynamicControllers[key]!.text = value.toString();
      }
    });
  }

  void _initializeDynamicControllers() {
    // Initialize controllers based on category to ensure they exist
    switch (_currentCategory) {
      case 'Comercio/retail':
      case 'Reciclaje Textil': // Handle Metamorfosis category
          _dynamicControllers['talla'] = TextEditingController();
          _dynamicControllers['color'] = TextEditingController();
          _dynamicControllers['material'] = TextEditingController();
          if (_currentCategory == 'Reciclaje Textil') {
             _dynamicControllers['pieza_unica'] = TextEditingController(text: 'Sí');
          }
        break;
      case 'Alimentos y gastronomía':
        _dynamicControllers['ingredientes'] = TextEditingController();
        _dynamicControllers['porcion'] = TextEditingController();
        _dynamicControllers['dietetico'] = TextEditingController(); // e.g. Vegano, Sin Gluten
        break;
      case 'Servicios profesionales':
        // Simplified for product-only context, though these categories hint at services.
        // Keeping basic fields or adapting if these should be products.
        // Assuming user wants to sell "service packages" as products if they use this screen.
        // But per request "solo debe ser productos", we remove pure service fields like duration unless it's a "packaged product"
         _dynamicControllers['modalidad'] = TextEditingController(); 
        break;
      case 'Salud, belleza y bienestar':
          _dynamicControllers['laboratorio'] = TextEditingController();
          _dynamicControllers['receta'] = TextEditingController();
        break;
      case 'Oficios y manufactura':
        _dynamicControllers['materiales'] = TextEditingController();
        _dynamicControllers['tiempo_entrega'] = TextEditingController();
        _dynamicControllers['personalizado'] = TextEditingController(text: 'No');
        break;
      case 'Educación y cultura':
         // Education products (books, kits) rather than classes
        _dynamicControllers['nivel'] = TextEditingController();
        _dynamicControllers['material_incluido'] = TextEditingController();
        break;
      case 'Transporte y logística':
        _dynamicControllers['tipo_vehiculo'] = TextEditingController();
        _dynamicControllers['capacidad'] = TextEditingController();
        break;
    }
  }

  // Force false as we separated events/services
  bool get _isService => false; 

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descController.dispose();
    for (var controller in _dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // Collect dynamic attributes
      Map<String, dynamic> attributes = {};
      _dynamicControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          attributes[key] = controller.text;
        }
      });

      final newProduct = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        pymeId: widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        name: _nameController.text,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        imageUrl: _imageController.text.isEmpty
            ? 'https://picsum.photos/200'
            : _imageController.text,
        code: _codeController.text,
        stock: int.tryParse(_stockController.text) ?? 0,
        category: _currentCategory,
        isService: widget.isService,
        customAttributes: attributes,
      );

      if (widget.product != null) {
        _productService.updateProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Actualizado en $_currentCategory exitosamente', style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA))),
            backgroundColor: const Color(0xFF2F3F2A),
          ),
        );
      } else {
        _productService.addProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto agregado a $_currentCategory exitosamente', style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA))),
            backgroundColor: const Color(0xFF2F3F2A),
          ),
        );
      }
      Navigator.pop(context);
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
                _buildTextField(_nameController, 'Nombre del Producto', Icons.label_outline),
                const SizedBox(height: 16),
                _buildTextField(_descController, 'Descripción', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_priceController, 'Precio', Icons.attach_money, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_codeController, 'Código (SKU)', Icons.qr_code, isRequired: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_stockController, 'Stock Disponible', Icons.inventory_2_outlined, isNumber: true),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Detalles Específicos'),
              _buildCard(_buildCategorySpecificFields()),

              const SizedBox(height: 24),
              _buildSectionTitle('Multimedia'),
              _buildCard([
                _buildTextField(_imageController, 'URL de la Imagen', Icons.image_outlined),
                const SizedBox(height: 10),
                if (_imageController.text.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageController.text, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox()),
                  )
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

  String _getStockLabel() {
    if (_isService) {
      return 'Cupos / Disponibilidad';
    }
    return 'Stock Disponible';
  }

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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
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
            _buildTextField(_dynamicControllers['talla']!, 'Talla / Medida', Icons.straighten),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['color']!, 'Color', Icons.palette_outlined),
            const SizedBox(height: 16),
            _buildTextField(_dynamicControllers['material']!, 'Material', Icons.layers_outlined),
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
              activeColor: const Color(0xFF6F8F5E),
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
            activeColor: const Color(0xFF6F8F5E),
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
            activeColor: const Color(0xFF6F8F5E),
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
