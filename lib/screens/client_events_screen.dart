import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class ClientEventsScreen extends StatelessWidget {
  const ClientEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F1EA),
        body: Center(child: Text('Debes iniciar sesión para ver tus eventos.', style: GoogleFonts.poppins())),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text('Mis Eventos y Talleres', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F3F2A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clients')
            .doc(user.uid)
            .collection('participations')
            .orderBy('eventDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                   ),
                   const SizedBox(height: 24),
                   Text(
                    'No te has inscrito a ningún evento aún.',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final eventName = data['eventName'] ?? 'Evento';
              final pymeName = data['pymeName'] ?? 'Organizador'; 
              final date = (data['eventDate'] as Timestamp?)?.toDate();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F3F2A).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                         // Could navigate to event detail Pyme page but pass event ID
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6F8F5E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    date != null ? DateFormat('dd').format(date) : '--',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF6F8F5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    date != null ? DateFormat('MMM').format(date).toUpperCase() : '--',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF6F8F5E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eventName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF2F3F2A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          pymeName,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (date != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('HH:mm').format(date),
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFE63946)),
                              tooltip: 'Cancelar inscripción',
                              onPressed: () => _confirmCancellation(context, snapshot.data!.docs[index].id, data),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmCancellation(BuildContext context, String participationDocId, Map<String, dynamic> data) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: Text('¿Seguro que deseas cancelar tu asistencia a "${data['eventName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar Inscripción'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // The docID in 'users/.../participations' is the eventId itself according to ClientPymeDetailScreen logic
      final eventId = participationDocId; 

      try {
        final eventRef = FirebaseFirestore.instance.collection('products').doc(eventId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final eventSnapshot = await transaction.get(eventRef);
          transaction.delete(FirebaseFirestore.instance
              .collection('clients')
              .doc(user.uid)
              .collection('participations')
              .doc(participationDocId));
          transaction.delete(eventRef.collection('participants').doc(user.uid));

          final data = eventSnapshot.data();
          final registeredCount = (data?['registeredCount'] as num?)?.toInt() ?? 0;
          if (registeredCount > 0) {
            transaction.update(eventRef, {
              'registeredCount': FieldValue.increment(-1),
            });
          }
        });
        

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscripción cancelada correctamente.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar: $e')),
          );
        }
      }
    }
  }
}
