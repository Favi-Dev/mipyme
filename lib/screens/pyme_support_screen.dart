import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/pyme_service.dart';

class PymeSupportScreen extends StatefulWidget {
  const PymeSupportScreen({super.key});

  @override
  State<PymeSupportScreen> createState() => _PymeSupportScreenState();
}

class _PymeSupportScreenState extends State<PymeSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final PymeService _pymeService = PymeService();
  bool _isLoading = false;

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _pymeService.createSupportTicket({
        'userId': user.uid,
        'email': user.email,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'type': 'pyme_support',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket enviado exitosamente')),
        );
        _subjectController.clear();
        _messageController.clear();
        Navigator.pop(context); // Close the dialog/modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo Ticket', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  hintText: 'Ej: Problema con pagos',
                ),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  hintText: 'Describe tu problema detalladamente...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              // Call submit but convert the modal context to local state logic
               _submitTicket();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6F8F5E),
              foregroundColor: Colors.white,
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text('Soporte Administración', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F1EA),
        foregroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketDialog,
        backgroundColor: const Color(0xFF6F8F5E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Ticket', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _pymeService.getUserTickets(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final tickets = snapshot.data ?? [];
          
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes tickets creados',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final date = ticket['createdAt'] as DateTime?;
              final dateStr = date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : '';
              final status = ticket['status'] ?? 'pending';
              
              Color statusColor;
              String statusText;
              
              switch(status) {
                case 'resolved':
                  statusColor = Colors.green;
                  statusText = 'Resuelto';
                  break;
                case 'in_progress':
                  statusColor = Colors.orange;
                  statusText = 'En Progreso';
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = 'Pendiente';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket['subject'] ?? 'Sin asunto',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket['message'] ?? '',
                        style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.8)),
                      ),
                      if (ticket['adminReply'] != null) ...[
                         const Divider(height: 24),
                         Text('Respuesta Administración:', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                         const SizedBox(height: 4),
                         Text(ticket['adminReply'], style: const TextStyle(fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
