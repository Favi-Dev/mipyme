import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class PymeAddProductScreen extends StatefulWidget {
  const PymeAddProductScreen({super.key});

  @override
  State<PymeAddProductScreen> createState() => _PymeAddProductScreenState();
}

class _PymeAddProductScreenState extends State<PymeAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedCategory;
  final _imageController = TextEditingController();
  final _descController = TextEditingController();

  final ProductService _productService = ProductService();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pymeId: 'pyme1', // Mocked current pyme
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        imageUrl: _imageController.text.isEmpty
            ? 'https://picsum.photos/200'
            : _imageController.text,
        code: _codeController.text,
        stock: int.parse(_stockController.text),
        category: _selectedCategory!,
      );

      _productService.addProduct(newProduct);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Código (SKU)'),
                validator: (value) =>
                    value!.isEmpty ? 'Por favor ingrese un código' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese precio' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese stock' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ProductService.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Seleccione una categoría' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL de Imagen'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
