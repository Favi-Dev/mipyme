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
                        icon: const Icon(Icons.email_outlined, color: Color(0xFF6F8F5E)),
                        onPressed: () {
                          // Could launch email app
                        },
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
}
