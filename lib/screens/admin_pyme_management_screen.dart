import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPymeManagementScreen extends StatelessWidget {
  const AdminPymeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Gestión de Pymes',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFE94560),
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'Pendientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPymeList(active: true),
            _buildPymeList(active: false),
          ],
        ),
      ),
    );
  }

  Widget _buildPymeList({required bool active}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildPymeTile(index, active);
      },
    );
  }

  Widget _buildPymeTile(int index, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/seed/${index + 50}/100/100'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          active ? 'Pyme Activa ${index + 1}' : 'Solicitud Pyme ${index + 1}',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Categoría • Dirección',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        trailing: active
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
      ),
    );
  }
}
