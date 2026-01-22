import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pyme_service.dart';

class PymeOffersManagementScreen extends StatefulWidget {
  final String? pymeId;
  const PymeOffersManagementScreen({super.key, this.pymeId});

  @override
  State<PymeOffersManagementScreen> createState() =>
      _PymeOffersManagementScreenState();
}

class _PymeOffersManagementScreenState
    extends State<PymeOffersManagementScreen> {
  final PymeService _pymeService = PymeService();
  String get _pymeId => widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _addOffer(Map<String, dynamic> offerData) async {
    if (_pymeId.isEmpty) return;
    await _pymeService.createOffer(_pymeId, offerData);
  }

  Future<void> _editOffer(String id, Map<String, dynamic> offerData) async {
    if (_pymeId.isEmpty) return;
    await _pymeService.updateOffer(_pymeId, id, offerData);
  }

  Future<void> _deleteOffer(String id) async {
    if (_pymeId.isEmpty) return;
    await _pymeService.deleteOffer(_pymeId, id);
  }

  void _showOfferDialog({Map<String, dynamic>? offer, String? offerId}) {
    final isEditing = offer != null;
    final titleController = TextEditingController(text: offer?['title'] ?? '');
    final descController = TextEditingController(text: offer?['description'] ?? '');
    
    // Default values
    IconData selectedIcon = offer != null && offer['iconCodePoint'] != null
        ? IconData(offer['iconCodePoint'], fontFamily: 'MaterialIcons') 
        : Icons.local_offer;
    Color selectedColor = offer != null && offer['colorValue'] != null
        ? Color(offer['colorValue']) 
        : const Color(0xFF6F8F5E);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF4F1EA),
            title: Text(
              isEditing ? 'Editar Oferta' : 'Nueva Oferta',
              style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A), fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Color(0xFF2F3F2A)),
                    decoration: InputDecoration(
                      labelText: 'Título',
                      labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.3))),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6F8F5E))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Color(0xFF2F3F2A)),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.3))),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6F8F5E))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Icono',
                      style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      Icons.local_offer,
                      Icons.star,
                      Icons.coffee,
                      Icons.cake,
                      Icons.fastfood,
                      Icons.percent,
                    ].map((icon) {
                      return ChoiceChip(
                        label: Icon(icon, size: 18, color: selectedIcon == icon ? const Color(0xFFF4F1EA) : const Color(0xFF2F3F2A)),
                        selected: selectedIcon == icon,
                        selectedColor: selectedColor,
                        backgroundColor: const Color(0xFF2F3F2A).withOpacity(0.1),
                        onSelected: (bool selected) {
                          setStateDialog(() {
                            selectedIcon = icon;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Color',
                      style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      const Color(0xFF6F8F5E),
                      const Color(0xFF2F3F2A),
                      const Color(0xFF8B5A3C),
                      const Color(0xFFE3B58F),
                    ].map((color) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: const Color(0xFF2F3F2A), width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar',
                    style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.6))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: const Color(0xFFF4F1EA),
                ),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    final newOfferData = {
                      'title': titleController.text,
                      'description': descController.text,
                      'iconCodePoint': selectedIcon.codePoint,
                      'colorValue': selectedColor.value,
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    
                    if (isEditing) {
                      _editOffer(offerId!, newOfferData);
                    } else {
                      _addOffer(newOfferData);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'Guardar' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
        title: Text(
          'Gestión de Ofertas',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF4F1EA),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF4F1EA)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6F8F5E),
        onPressed: () => _showOfferDialog(),
        child: const Icon(Icons.add, color: Color(0xFFF4F1EA)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _pymeService.getOffersByPyme(_pymeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: const Color(0xFF2F3F2A).withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ofertas activas',
                    style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final icon = IconData(offer['iconCodePoint'] ?? Icons.local_offer.codePoint, fontFamily: 'MaterialIcons');
                final color = Color(offer['colorValue'] ?? 0xFF6F8F5E);
                
                return Dismissible(
                  key: Key(offer['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: const Color(0xFF8B5A3C),
                    child: const Icon(Icons.delete, color: Color(0xFFF4F1EA)),
                  ),
                  onDismissed: (direction) => _deleteOffer(offer['id']),
                  child: Card(
                    color: const Color(0xFFFFFFFF),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        offer['title'] ?? '',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F3F2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          offer['description'] ?? '',
                          style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
                        onPressed: () => _showOfferDialog(offer: offer, offerId: offer['id']),
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
}
