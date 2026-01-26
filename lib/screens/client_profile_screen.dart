import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/client_service.dart';
import '../services/pyme_service.dart';
import '../models/vitrina_data.dart';
import '../models/user_profile.dart';
import '../services/product_service.dart';
import 'client_pyme_detail_screen.dart';
import 'login_screen.dart';
import 'client_payment_methods_screen.dart';
import 'client_payments_subscriptions_screen.dart';
import '../widgets/supporter_counter.dart';
import 'client_qr_screen.dart';
import 'client_history_screen.dart';
import 'client_settings_screen.dart';
import 'client_support_screen.dart';
import 'client_addresses_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final ClientService _clientService = ClientService();
  bool _isUploading = false;
  
  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final File imageFile = File(image.path);
      await _clientService.updateProfileImage(imageFile);
      
      // Force reload auth user to get new photoURL if needed, 
      // though the stream below should catch it.
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final pymeService = PymeService();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile Header
            Center(
              child: Column(
                children: [
                   Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 3),
                          image: DecorationImage(
                            image: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                                ? NetworkImage(user.photoURL!)
                                : const NetworkImage('https://i.pravatar.cc/300'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.displayName ?? 'Usuario',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                        children: const [
                          TextSpan(text: 'Beneficiario '),
                          TextSpan(
                            text: 'Plus',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Menu Options
            _buildProfileOption(
              context,
              icon: Icons.confirmation_number,
              title: 'Mi Cupón',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientQrScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.history,
              title: 'Historial de Compras',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientHistoryScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.payment,
              title: 'Métodos de Pago',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientPaymentMethodsScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.receipt_long,
              title: 'Pagos y Suscripciones',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientPaymentsSubscriptionsScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.location_on,
              title: 'Mis Direcciones',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientAddressesScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientSettingsScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.help,
              title: 'Ayuda y Soporte',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientSupportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            
            // Supported Pymes & Foundations
            if (user != null)
              StreamBuilder<List<String>>(
                stream: pymeService.getFollowedPymeIds(user.uid),
                builder: (context, snapshotIds) {
                  if (!snapshotIds.hasData || snapshotIds.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final followedIds = snapshotIds.data!.toSet();

                  return StreamBuilder<List<UserProfile>>(
                    stream: pymeService.getAllPublicProfiles(),
                    builder: (context, snapshotPymes) {
                      if (!snapshotPymes.hasData) return const SizedBox.shrink();
                      
                      final allPymes = snapshotPymes.data!;
                      final followedPymes = allPymes.where((p) => followedIds.contains(p.id)).toList();
                      
                      final foundations = followedPymes.where((p) => p.role == UserRole.foundation).toList();
                      final pymes = followedPymes.where((p) => p.role == UserRole.pyme).toList();

                      return Column(
                        children: [
                          if (foundations.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fundaciones que apoyas',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...foundations.map((f) => _buildSupportedCard(context, f, isFoundation: true)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (pymes.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pymes que apoyas',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...pymes.map((p) => _buildSupportedCard(context, p, isFoundation: false)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              color: theme.colorScheme.error,
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveColor == theme.colorScheme.error 
              ? theme.colorScheme.error.withValues(alpha: 0.1) 
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: effectiveColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildSupportedCard(BuildContext context, UserProfile data, {required bool isFoundation}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(data.logoUrl ?? 'https://via.placeholder.com/150'),
        ),
        title: Text(data.name),
        subtitle: Text(data.category ?? (isFoundation ? 'Fundación' : 'Comercio')),
        trailing: const Icon(Icons.favorite, color: Colors.red),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientPymeDetailScreen(
                pymeId: data.id,
                pymeData: data,
              ),
            ),
          );
        },
      ),
    );
  }
}
