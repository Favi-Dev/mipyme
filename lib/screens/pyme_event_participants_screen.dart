import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PymeEventParticipantsScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const PymeEventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F3F2A))),
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F3F2A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Enviar recordatorio a todos',
            onPressed: () => _showNotificationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(eventId)
            .collection('participants')
            .orderBy('registeredAt', descending: true)
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
                   Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text('Aún no hay participantes inscritos.', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final participants = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Total inscritos:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F8F5E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${participants.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: participants.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = participants[index].data() as Map<String, dynamic>;
                    final participantId = participants[index].id;
                    final email = data['email'] ?? 'Sin correo';
                    final registeredAt = (data['registeredAt'] as Timestamp?)?.toDate();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Text(email[0].toUpperCase(), style: const TextStyle(color: Colors.black54)),
                      ),
                      title: Text(email, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: registeredAt != null 
                          ? Text('Inscrito el: ${DateFormat('dd/MM/yyyy HH:mm').format(registeredAt)}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE63946)),
                        tooltip: 'Eliminar participante',
                        onPressed: () => _confirmRemoval(context, participantId, email),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Notificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escribe un mensaje para enviar a TODOS los participantes inscritos.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Ej: Recuerden traer ropa cómoda...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3F2A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Enviar'),
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _sendNotificationToAll(context, messageController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToAll(BuildContext context, String message) async {
    // Show loading
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviando notificaciones...')));
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(eventId)
          .collection('participants')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final userId = doc.id; // The doc ID in participants is the userId
        final notifRef = FirebaseFirestore.instance
            .collection('clients')
            .doc(userId)
            .collection('notifications')
            .doc();
        
        batch.set(notifRef, {
          'title': 'Recordatorio: $eventName',
          'message': message,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'event_reminder',
          'eventId': eventId,
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notificación enviada a ${snapshot.docs.length} participantes.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enviando notificaciones: $e')),
        );
      }
    }
  }

  Future<void> _confirmRemoval(BuildContext context, String participantId, String email) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Participante'),
        content: Text('¿Seguro que deseas eliminar a "$email" de este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
       try {
         final eventRef = FirebaseFirestore.instance.collection('products').doc(eventId);
         await FirebaseFirestore.instance.runTransaction((transaction) async {
           final eventSnapshot = await transaction.get(eventRef);
           transaction.delete(eventRef.collection('participants').doc(participantId));
           transaction.delete(FirebaseFirestore.instance
               .collection('clients')
               .doc(participantId)
               .collection('participations')
               .doc(eventId));

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
             const SnackBar(content: Text('Participante eliminado.')),
           );
         }
       } catch (e) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al eliminar: $e')),
           );
         }
       }
    }
  }
}
