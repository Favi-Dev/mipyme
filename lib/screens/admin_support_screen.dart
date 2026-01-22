import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminService = AdminService();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Soporte y Tickets',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.primary),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: adminService.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar tickets: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)));
          }

           final tickets = snapshot.data ?? [];
           if (tickets.isEmpty) {
             return Center(child: Text('No hay tickets pendientes', style: GoogleFonts.poppins()));
           }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketTile(ticket: ticket, theme: theme, adminService: adminService);
            },
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir del panel de administración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
               await FirebaseAuth.instance.signOut();
               if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
               }
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final ThemeData theme;
  final AdminService adminService;

  const _TicketTile({required this.ticket, required this.theme, required this.adminService});

  @override
  Widget build(BuildContext context) {
    // Determine priority based on issue type (Basic mapping)
    // "Account Access" -> High, "Payment Issue" -> High, "Bug Report" -> Medium
    final issueType = ticket['issueType'] ?? 'Other';
    final isSolved = ticket['status'] == 'solved';
    
    Color priorityColor;
    String priorityText;

    if (['Account Access', 'Payment Issue'].contains(issueType)) {
      priorityColor = theme.colorScheme.error;
      priorityText = 'Alta';
    } else if (['Bug Report'].contains(issueType)) {
      priorityColor = theme.colorScheme.secondary;
      priorityText = 'Media';
    } else {
      priorityColor = theme.colorScheme.primary;
      priorityText = 'Baja';
    }

    if (isSolved) {
      priorityColor = Colors.grey;
      priorityText = 'Resuelto';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: priorityColor,
            width: 4,
          ),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          'Ticket #${ticket['id'].toString().length > 5 ? ticket['id'].toString().substring(0, 5) : ticket['id']}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          issueType,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            priorityText,
            style: theme.textTheme.labelLarge?.copyWith(
              color: priorityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(ticket['description'] ?? 'Sin descripción'),
                const SizedBox(height: 16),
                if (!isSolved)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await adminService.resolveTicket(ticket['id']);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Marcar como Resuelto'),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}
