import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

class ClientEventsScreen extends StatelessWidget {
  const ClientEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver tus eventos.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: const Text('Mis Eventos y Talleres', style: TextStyle(color: Color(0xFF2F3F2A), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2F3F2A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query products where user is in participants subcollection...
        // Firestore doesn't support collection group queries on subcollections easily for "my participation"
        // unless we store multiple documents or duplicate data.
        // A better approach: Store `participations` collection at root: { userId, eventId, eventDetails... }
        // BUT current implementation in ClientPymeDetailScreen stores in `products/{id}/participants/{uid}`.
        // To list "My Events", we either:
        // 1. Traverse all products (inefficient).
        // 2. Change data model to also store in users/{uid}/participations or a root `participations` collection.
        // Given I just wrote the previous code to write to `products/.../participants`, I should update it to ALSO write to `users/{uid}/participations`.
        
        // Let's assume for now I will fix the write logic to also save to user profile or root collection.
        // I'll update ClientPymeDetailScreen to save to `users/{uid}/participations` as well.
        stream: FirebaseFirestore.instance
            .collection('users')
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
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No te has inscrito a ningún evento aún.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
              final pymeName = data['pymeName'] ?? 'Organizador'; // Assuming we save this
              final date = (data['eventDate'] as Timestamp?)?.toDate();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event, color: Color(0xFFE63946)),
                  ),
                  title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pymeName),
                      if (date != null)
                        Text(DateFormat('dd/MM/yyyy HH:mm').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: const Chip(
                    label: Text('Inscrito', style: TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: Color(0xFF6F8F5E),
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
