import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController(); // Nombre Completo / Rep. Legal
  final _runController = TextEditingController(); // RUN (Cliente)
  final _companyNameController = TextEditingController(); // Razón Social (PYME/Fundación)
  final _commercialNameController = TextEditingController(); // Nombre Comercial (PYME)
  final _rutController = TextEditingController(); // RUT Empresa / Fundación
  final _repRutController = TextEditingController(); // RUT Representante Legal
  final _giroController = TextEditingController(); // Giro (PYME)
  final _contactRoleController = TextEditingController(); // Cargo
  final _phoneController = TextEditingController(); // Teléfono
  final _addressController = TextEditingController(); // Domicilio Tributario / Dirección Legal
  final _websiteController = TextEditingController(); // Sitio Web
  final _legalStatusController = TextEditingController(); // N° Personalidad Jurídica (Fundación)
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.client;
  String? _selectedCategory;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    // Validaciones específicas por rol (Chile)
    if (_selectedRole == UserRole.pyme) {
      if (_rutController.text.isEmpty) {
        _showError('Ingrese el RUT de la Empresa');
        return;
      }
      if (_companyNameController.text.isEmpty) {
        _showError('Ingrese la Razón Social');
        return;
      }
      if (_giroController.text.isEmpty) {
        _showError('Ingrese el Giro (Actividad Económica)');
        return;
      }
      if (_nameController.text.isEmpty) {
        _showError('Ingrese el Nombre del Representante Legal');
        return;
      }
      if (_repRutController.text.isEmpty) {
        _showError('Ingrese el RUT del Representante Legal');
        return;
      }
      if (_addressController.text.isEmpty) {
        _showError('Ingrese el Domicilio Tributario');
        return;
      }
      if (_selectedCategory == null) {
        _showError('Seleccione una categoría');
        return;
      }
    } else if (_selectedRole == UserRole.foundation) {
      if (_rutController.text.isEmpty) {
        _showError('Ingrese el RUT de la Fundación');
        return;
      }
      if (_companyNameController.text.isEmpty) {
        _showError('Ingrese la Razón Social');
        return;
      }
      if (_legalStatusController.text.isEmpty) {
        _showError('Ingrese N° Personalidad Jurídica / Certificado');
        return;
      }
      if (_nameController.text.isEmpty) {
        _showError('Ingrese el Nombre del Representante Legal');
        return;
      }
      if (_repRutController.text.isEmpty) {
        _showError('Ingrese el RUT del Representante Legal');
        return;
      }
      if (_addressController.text.isEmpty) {
        _showError('Ingrese la Dirección Legal');
        return;
      }
    } else {
      // Cliente
      if (_runController.text.isEmpty) {
        _showError('Ingrese su RUN');
        return;
      }
      if (_nameController.text.isEmpty) {
        _showError('Ingrese su Nombre Completo');
        return;
      }
    }

    setState(() => _isLoading = true);

    // In a real app, pass all these new fields to the backend
    final success = await AuthService.register(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
      _selectedRole,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Por favor inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to login
    } else {
      _showError('Error en el registro');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B5A3C)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F3F2A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Crear Cuenta',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2F3F2A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Únete a la comunidad SoyPlus',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2F3F2A).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Role Selection
              Row(
                children: [
                  Expanded(
                    child: _buildRoleOption(
                      'Cliente',
                      Icons.person,
                      UserRole.client,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleOption(
                      'Pyme',
                      Icons.storefront,
                      UserRole.pyme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleOption(
                      'Fundación',
                      Icons.volunteer_activism,
                      UserRole.foundation,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields based on Role
              if (_selectedRole == UserRole.client) ...[
                _buildSectionTitle('Identificación'),
                TextField(
                  controller: _runController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUN (Rol Único Nacional) *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Nombre Completo *', Icons.person_outline),
                ),
              ],

              if (_selectedRole == UserRole.pyme) ...[
                _buildSectionTitle('Identificación'),
                TextField(
                  controller: _rutController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Empresa *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyNameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Razón Social *', Icons.business),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commercialNameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Nombre Comercial (Opcional)', Icons.store),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _giroController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Giro (Actividad Económica) *', Icons.work),
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Contacto'),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Nombre Representante Legal *', Icons.person),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _repRutController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Representante Legal *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Teléfono de Contacto *', Icons.phone),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Ubicación'),
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Domicilio Tributario *', Icons.location_on),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Validación'),
                TextField(
                  controller: _websiteController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Sitio Web / Red Social (Opcional)', Icons.language),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Categoría *', Icons.category),
                  dropdownColor: const Color(0xFFFFFFFF),
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
                ),
              ],

              if (_selectedRole == UserRole.foundation) ...[
                _buildSectionTitle('Identificación'),
                TextField(
                  controller: _rutController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Fundación *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyNameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Razón Social *', Icons.business),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _legalStatusController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('N° Personalidad Jurídica / Certificado *', Icons.confirmation_number),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Contacto'),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Nombre Representante Legal *', Icons.person),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _repRutController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Representante Legal *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Teléfono de Contacto *', Icons.phone),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Ubicación'),
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Dirección Legal Completa *', Icons.location_on),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Validación'),
                TextField(
                  controller: _websiteController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Sitio Web / Memoria Anual (Opcional)', Icons.language),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionTitle('Cuenta'),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFF2F3F2A)),
                decoration: _inputDecoration('Correo Electrónico *', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Color(0xFF2F3F2A)),
                decoration: _inputDecoration('Contraseña *', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF2F3F2A).withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Color(0xFF2F3F2A)),
                decoration: _inputDecoration('Confirmar Contraseña *', Icons.lock_outline),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    foregroundColor: const Color(0xFFF4F1EA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF4F1EA),
                          ),
                        )
                      : Text(
                          'Registrarse',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2F3F2A),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String label, IconData icon, UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6F8F5E) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6F8F5E) : const Color(0xFF2F3F2A).withOpacity(0.1),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: const Color(0xFF2F3F2A).withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF4F1EA) : const Color(0xFF2F3F2A).withOpacity(0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFFF4F1EA) : const Color(0xFF2F3F2A).withOpacity(0.6),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
      prefixIcon: Icon(icon, color: const Color(0xFF2F3F2A).withOpacity(0.7)),
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
        borderSide: const BorderSide(color: Color(0xFF6F8F5E), width: 2),
      ),
    );
  }
}
