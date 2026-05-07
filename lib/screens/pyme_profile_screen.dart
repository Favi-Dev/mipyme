import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/pyme_service.dart';
import '../models/user_profile.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pyme_vitrina_settings_screen.dart';
import 'pyme_support_screen.dart';

class PymeProfileScreen extends StatefulWidget {
  const PymeProfileScreen({super.key});

  @override
  State<PymeProfileScreen> createState() => _PymeProfileScreenState();
}

class _PymeProfileScreenState extends State<PymeProfileScreen> {
  final PymeService _pymeService = PymeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text(
            'Se enviará un correo electrónico a tu dirección registrada para restablecer tu contraseña.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = _auth.currentUser?.email;
                if (email != null) {
                  await _auth.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Correo enviado a $email')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Enviar Correo'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Términos y Condiciones de Uso', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('• El uso de esta aplicación está sujeto a las leyes vigentes.', style: TextStyle(fontSize: 14)),
              Text('• Respetamos tu privacidad y datos personales.', style: TextStyle(fontSize: 14)),
              Text('• Las transacciones son seguras y procesadas por proveedores confiables.', style: TextStyle(fontSize: 14)),
              SizedBox(height: 10),
              Text('Para más detalles, visita nuestro sitio web oficial.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const SizedBox();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FutureBuilder<UserProfile?>(
        future: _pymeService.getPymeById(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          if (userData == null) {
             return const Center(child: Text('Error al cargar el perfil'));
          }
          
          final companyName = userData.name;
          final email = userData.email;
          final logoUrl = userData.logoUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileHeader(companyName, email, logoUrl),
              const SizedBox(height: 24),
              _buildSectionTitle('Cuenta'),
              _buildOptionTile(
                icon: Icons.person_outline,
                title: 'Editar Perfil',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PymeVitrinaSettingsScreen(),
                    ),
                  );
                  setState(() {}); // Refresh after edit
                },
              ),
              _buildOptionTile(
                icon: Icons.account_balance, // Changed icon to represent bank
                title: 'Datos Bancarios', // Changed title
                onTap: () {
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: Text('Datos Bancarios Registrados', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                       content: Column(
                         mainAxisSize: MainAxisSize.min,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           _buildBankDetail('Banco:', userData.bankName),
                           _buildBankDetail('Tipo de Cuenta:', userData.bankAccountType),
                           _buildBankDetail('N° Cuenta:', userData.bankAccountNumber),
                           _buildBankDetail('RUT Titular:', userData.bankAccountHolderRut),
                         ],
                       ),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: const Text('Cerrar'),
                         ),
                       ],
                     ),
                   );
                },
              ),
              _buildOptionTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contraseña',
                onTap: () {
                  _changePassword(context);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Configuración'),
               _buildOptionTile(
                icon: Icons.settings_outlined,
                title: 'Ajustes de Cuenta',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PymeVitrinaSettingsScreen(),
                    ),
                  );
                  setState(() {});
                },
              ),
              SwitchListTile(
                  title: Text(
                    'Notificaciones',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: _notificationsEnabled, 
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: _toggleNotifications,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary, size: 20),
                  ),
              ),
              // Dark mode toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  title: Text(
                    'Modo Oscuro',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: themeProvider.isDarkMode,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Soporte'),
              _buildOptionTile(
                icon: Icons.help_outline,
                title: 'Ayuda y Soporte',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PymeSupportScreen()),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.info_outline,
                title: 'Términos y Condiciones',
                onTap: () {
                   _showTerms(context);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5A3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                child: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? logoUrl) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
            child: ClipOval(
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.store, size: 30, color: theme.colorScheme.primary),
                    )
                  : Icon(Icons.store, size: 30, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
    );
  }
  Widget _buildBankDetail(String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(color: theme.colorScheme.onSurface),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'No registrado'),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}
