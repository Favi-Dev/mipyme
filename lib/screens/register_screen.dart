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
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.client;
  String? _selectedCategory;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (_selectedRole == UserRole.pyme || _selectedRole == UserRole.foundation) {
      if (_companyNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedRole == UserRole.foundation ? 'Por favor ingrese el Nombre de la Fundación' : 'Por favor ingrese el Nombre de la Empresa')),
        );
        return;
      }
      if (_businessNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingrese la Razón Social')),
        );
        return;
      }
      if (_selectedRole == UserRole.pyme && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione una categoría')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    // In a real app, pass businessName and category to the backend
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en el registro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Únete a la comunidad SoyPlus',
                style: theme.textTheme.bodyMedium,
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
              TextField(
                controller: _nameController,
                decoration: _inputDecoration(
                  (_selectedRole == UserRole.pyme || _selectedRole == UserRole.foundation) ? 'Nombre del Representante' : 'Nombre Completo',
                  Icons.person_outline,
                ),
              ),
              if (_selectedRole == UserRole.pyme || _selectedRole == UserRole.foundation) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _companyNameController,
                  decoration: _inputDecoration(_selectedRole == UserRole.foundation ? 'Nombre de la Fundación' : 'Nombre de la Empresa', Icons.store),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _businessNameController,
                  decoration: _inputDecoration('Razón Social', Icons.business),
                ),
                if (_selectedRole == UserRole.pyme) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _inputDecoration('Categoría', Icons.category),
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
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('Contraseña', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                decoration: _inputDecoration('Confirmar Contraseña', Icons.lock_outline),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Registrarse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String label, IconData icon, UserRole role) {
    final theme = Theme.of(context);
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.disabledColor.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.bold,
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
      prefixIcon: Icon(icon),
    );
  }
}
