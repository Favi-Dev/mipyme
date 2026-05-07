import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/empresa_service.dart';
import '../../models/user_profile.dart';

class EmpresaStoresScreen extends StatefulWidget {
  const EmpresaStoresScreen({super.key});

  @override
  State<EmpresaStoresScreen> createState() => _EmpresaStoresScreenState();
}

class _EmpresaStoresScreenState extends State<EmpresaStoresScreen> {
  final EmpresaService _empresaService = EmpresaService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        title: const Text('Mis Tiendas', style: TextStyle(color: Color(0xFFF4F1EA), fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6F8F5E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Tienda'),
        onPressed: () => _showCreateStoreDialog(),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _empresaService.getStoresByEmpresa(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stores = snapshot.data ?? [];
          if (stores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes tiendas registradas aún',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón "+" para crear tu primera tienda',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6F8F5E).withValues(alpha: 0.12),
                    backgroundImage: store.logoUrl != null && store.logoUrl!.startsWith('http')
                        ? NetworkImage(store.logoUrl!)
                        : null,
                    child: store.logoUrl == null || !store.logoUrl!.startsWith('http')
                        ? const Icon(Icons.storefront, color: Color(0xFF6F8F5E))
                        : null,
                  ),
                  title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(store.category ?? 'Sin categoría'),
                  trailing: Text(
                    store.location ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateStoreDialog() {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Crear Nueva Tienda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2F3F2A))),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de la tienda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  labelText: 'Categoría (ej: Comercio/retail)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      await _empresaService.createStore(
                        empresaId: _uid,
                        name: nameCtrl.text.trim(),
                        category: categoryCtrl.text.trim().isEmpty ? 'Comercio/retail' : categoryCtrl.text.trim(),
                        location: locationCtrl.text.trim(),
                        description: descriptionCtrl.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Tienda creada exitosamente'), backgroundColor: Color(0xFF6F8F5E)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Crear Tienda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
