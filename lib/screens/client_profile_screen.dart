import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary, width: 3),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/300'),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                    child: Text(
                      'Plan Premium',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
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
