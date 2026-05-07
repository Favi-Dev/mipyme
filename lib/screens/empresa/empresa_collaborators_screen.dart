import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/empresa_service.dart';
import '../../models/user_profile.dart';

class EmpresaCollaboratorsScreen extends StatefulWidget {
  const EmpresaCollaboratorsScreen({super.key});

  @override
  State<EmpresaCollaboratorsScreen> createState() => _EmpresaCollaboratorsScreenState();
}

class _EmpresaCollaboratorsScreenState extends State<EmpresaCollaboratorsScreen> {
  final EmpresaService _empresaService = EmpresaService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        title: const Text('Colaboradores', style: TextStyle(color: Color(0xFFF4F1EA), fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6F8F5E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Jefe de Tienda'),
        onPressed: () => _showCreateManagerDialog(),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _empresaService.getStoreManagersByEmpresa(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final managers = snapshot.data ?? [];
          if (managers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes colaboradores aún',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea un Jefe de Tienda y asígnalo a una de tus tiendas',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: managers.length,
            itemBuilder: (context, index) {
              final m = managers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF8B5A3C).withValues(alpha: 0.12),
                    child: const Icon(Icons.person, color: Color(0xFF8B5A3C)),
                  ),
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 14, color: Color(0xFF6F8F5E)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              m.assignedStoreName ?? 'Sin tienda asignada',
                              style: const TextStyle(color: Color(0xFF6F8F5E), fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateManagerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final rutCtrl = TextEditingController();
    String? selectedStoreId;
    String? selectedStoreName;
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                  const Text('Crear Jefe de Tienda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2F3F2A))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña temporal',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rutCtrl,
                    decoration: InputDecoration(
                      labelText: 'RUT (opcional)',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selector de tienda
                  StreamBuilder<List<UserProfile>>(
                    stream: _empresaService.getStoresByEmpresa(_uid),
                    builder: (context, snap) {
                      final stores = snap.data ?? [];
                      if (stores.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(child: Text('Primero debes crear al menos una tienda', style: TextStyle(color: Colors.orange))),
                            ],
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedStoreId,
                        decoration: InputDecoration(
                          labelText: 'Asignar a tienda',
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: stores.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedStoreId = val;
                            selectedStoreName = stores.firstWhere((s) => s.id == val).name;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCreating ? null : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty ||
                            passwordCtrl.text.trim().isEmpty ||
                            selectedStoreId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Completa todos los campos obligatorios'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        setModalState(() => isCreating = true);
                        try {
                          await _empresaService.createStoreManager(
                            empresaId: _uid,
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            assignedStoreId: selectedStoreId!,
                            assignedStoreName: selectedStoreName ?? '',
                            rut: rutCtrl.text.trim(),
                          );

                          if (context.mounted) Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Colaborador creado exitosamente.'),
                                backgroundColor: Color(0xFF6F8F5E),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isCreating = false);
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
                      child: isCreating
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Crear Colaborador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
