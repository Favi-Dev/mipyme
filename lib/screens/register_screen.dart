import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart'; // Added go_router import
import 'package:mipyme/services/auth_service.dart';
import 'package:mipyme/services/product_service.dart';
import 'package:mipyme/models/user_profile.dart';
import 'package:mipyme/utils/rut_formatter.dart';

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
  // final _contactRoleController = TextEditingController(); // Cargo (unused)
  final _phoneController = TextEditingController(); // Teléfono
  final _addressController = TextEditingController(); // Domicilio Tributario / Dirección Legal
  final _websiteController = TextEditingController(); // Sitio Web
  final _legalStatusController = TextEditingController(); // N° Personalidad Jurídica (Fundación)
  
  // Bank Account Controllers
  // final _bankNameController = TextEditingController();
  // final _bankAccountTypeController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderRutController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.client;
  String? _selectedCategory;
  String? _selectedBank;
  String? _selectedAccountType;

  final List<String> _banks = [
    'Banco Estado',
    'Banco de Chile',
    'Banco Santander',
    'Banco BCI',
    'Banco Scotiabank',
    'Banco Itaú',
    'Banco Falabella',
    'Banco Ripley',
    'Banco Consorcio',
    'Banco Security',
    'Banco Internacional',
    'Coopeuch',
    'Tenpo',
    'Mercado Pago',
    'Mach',
  ];

  final List<String> _accountTypes = [
    'Cuenta Corriente',
    'Cuenta Vista / RUT',
    'Cuenta de Ahorro',
    'Chequera Electrónica',
  ];

  void _register() async {
    // Password Strength Check
    final password = _passwordController.text;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    if (!hasMinLength || !hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialCharacters) {
      _showError('La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    // Validaciones específicas por rol (Chile)
    if (_selectedRole == UserRole.empresa) {
      if (_rutController.text.isEmpty) {
        _showError('Ingrese el RUT de la Empresa');
        return;
      }
      if (_companyNameController.text.isEmpty) {
        _showError('Ingrese la Razón Social');
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
      if (_phoneController.text.isNotEmpty && !_isValidChileanPhone(_phoneController.text)) {
        _showError('Teléfono inválido. Formato: 9XXXXXXXX (9 dígitos, comenzando con 9)');
        return;
      }
    } else if (_selectedRole == UserRole.pyme) {
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
      if (_phoneController.text.isNotEmpty && !_isValidChileanPhone(_phoneController.text)) {
        _showError('Teléfono inválido. Formato: 9XXXXXXXX (9 dígitos, comenzando con 9)');
        return;
      }
      if (_selectedCategory == null) {
        _showError('Seleccione una categoría');
        return;
      }
      // Bank Validation
      if (_selectedBank == null || _selectedAccountType == null || _bankAccountNumberController.text.isEmpty) {
        _showError('Complete los datos bancarios para recibir pagos');
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
      if (_phoneController.text.isNotEmpty && !_isValidChileanPhone(_phoneController.text)) {
        _showError('Teléfono inválido. Formato: 9XXXXXXXX (9 dígitos, comenzando con 9)');
        return;
      }
      // Bank Validation
      if (_selectedBank == null || _selectedAccountType == null || _bankAccountNumberController.text.isEmpty) {
        _showError('Complete los datos bancarios para recibir donaciones');
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

    Map<String, dynamic> additionalData = {};
    if (_selectedRole == UserRole.pyme) {
      additionalData = {
        'rut': _rutController.text,
        'companyName': _companyNameController.text,
        'commercialName': _commercialNameController.text,
        'giro': _giroController.text,
        'repRut': _repRutController.text,
        'address': _addressController.text,
        'website': _websiteController.text,
        'category': _selectedCategory,
        'bankName': _selectedBank,
        'bankAccountType': _selectedAccountType,
        'bankAccountNumber': _bankAccountNumberController.text,
        'bankAccountHolderRut': _bankAccountHolderRutController.text.isNotEmpty 
            ? _bankAccountHolderRutController.text 
            : _rutController.text,
      };
    } else if (_selectedRole == UserRole.foundation) {
      additionalData = {
        'rut': _rutController.text,
        'companyName': _companyNameController.text,
        'legalStatus': _legalStatusController.text,
        'repRut': _repRutController.text,
        'address': _addressController.text,
        'website': _websiteController.text,
        'bankName': _selectedBank,
        'bankAccountType': _selectedAccountType,
        'bankAccountNumber': _bankAccountNumberController.text,
        'bankAccountHolderRut': _bankAccountHolderRutController.text.isNotEmpty 
            ? _bankAccountHolderRutController.text 
            : _rutController.text,
      };
    } else if (_selectedRole == UserRole.empresa) {
      additionalData = {
        'rut': _rutController.text,
        'companyName': _companyNameController.text,
        'repRut': _repRutController.text,
        'address': _addressController.text,
        'website': _websiteController.text,
        'phone': _phoneController.text,
      };
    } else {
      additionalData = {
        'run': _runController.text,
      };
    }

    // Intentar obtener coordenadas para Pymes y Fundaciones
    if (_selectedRole == UserRole.pyme || _selectedRole == UserRole.foundation || _selectedRole == UserRole.empresa) {
      try {
        // Añadir "Chile" para mejorar la precisión si no está incluido
        String addressToSearch = _addressController.text;
        if (!addressToSearch.toLowerCase().contains('chile')) {
          addressToSearch += ', Chile';
        }
        
        List<Location> locations = await locationFromAddress(addressToSearch);
        if (locations.isNotEmpty) {
          additionalData['latitude'] = locations.first.latitude;
          additionalData['longitude'] = locations.first.longitude;
        }
      } catch (e) {
        debugPrint('Error obteniendo coordenadas: $e');
        // No bloqueamos el registro, pero no tendrá ubicación en el mapa
      }
    }

    final success = await AuthService().register(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
      _selectedRole,
      additionalData: additionalData,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada con éxito. Hemos enviado un correo de verificación. Por favor verifícalo antes de iniciar sesión.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      
      // Navigate back to login
      _goToLogin();
    } else {
      _showError('Error en el registro');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B5A3C)),
    );
  }

  bool _isValidChileanPhone(String phone) {
    // Acepta: 9XXXXXXXX | +569XXXXXXXX | 569XXXXXXXX
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(\+?56)?9\d{8}$').hasMatch(cleaned);
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F3F2A)),
          onPressed: () {
            _goToLogin();
          },
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
              Column(
                children: [
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
                          'Empresa',
                          Icons.business,
                          UserRole.empresa,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields based on Role
              if (_selectedRole == UserRole.client) ...[
                _buildSectionTitle('Identificación'),
                TextField(
                  controller: _runController,
                  inputFormatters: [RutInputFormatter()],
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
                  inputFormatters: [RutInputFormatter()],
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
                  inputFormatters: [RutInputFormatter()],
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
                  initialValue: _selectedCategory,
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
                  inputFormatters: [RutInputFormatter()],
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
                  inputFormatters: [RutInputFormatter()],
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

              if (_selectedRole == UserRole.empresa) ...[
                _buildSectionTitle('Identificación (Empresa)'),
                TextField(
                  controller: _rutController,
                  inputFormatters: [RutInputFormatter()],
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Empresa *', Icons.badge),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyNameController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Razón Social *', Icons.business),
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
                  inputFormatters: [RutInputFormatter()],
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

                _buildSectionTitle('Ubicación Central'),
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Dirección Legal *', Icons.location_on),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Sitio Web'),
                TextField(
                  controller: _websiteController,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Sitio Web / Red Social (Opcional)', Icons.language),
                ),
              ],

              if (_selectedRole == UserRole.pyme || _selectedRole == UserRole.foundation) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(_selectedRole == UserRole.foundation 
                    ? 'Datos Bancarios (Para recibir donaciones)' 
                    : 'Datos Bancarios (Para recibir pagos)'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBank,
                  decoration: _inputDecoration('Banco *', Icons.account_balance),
                  items: _banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedBank = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountType,
                  decoration: _inputDecoration('Tipo de Cuenta *', Icons.credit_card),
                  items: _accountTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAccountType = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bankAccountNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('Número de Cuenta *', Icons.numbers),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bankAccountHolderRutController,
                  inputFormatters: [RutInputFormatter()],
                  style: const TextStyle(color: Color(0xFF2F3F2A)),
                  decoration: _inputDecoration('RUT Titular (Si es distinto al de la empresa)', Icons.badge),
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
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2F3F2A).withOpacity(0.7),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Inicia sesión aquí',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6F8F5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
