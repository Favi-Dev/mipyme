import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPymeManagementScreen extends StatelessWidget {
  const AdminPymeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Gestión de Pymes',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF6B6B),
            labelColor: Color(0xFFFF6B6B),
            unselectedLabelColor: Colors.grey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/seed/${index + 50}/100/100'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          active ? 'Pyme Activa ${index + 1}' : 'Solicitud Pyme ${index + 1}',
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Categoría • Dirección',
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: active
            ? const Icon(Icons.check_circle, color: Color(0xFF4ECDC4))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF4ECDC4)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFFF6B6B)),
                    onPressed: () {},
                  ),
                ],
              ),
      ),
    );
  }
}
