import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/offer_data.dart';

class PymeOffersManagementScreen extends StatefulWidget {
  const PymeOffersManagementScreen({super.key});

  @override
  State<PymeOffersManagementScreen> createState() =>
      _PymeOffersManagementScreenState();
}

class _PymeOffersManagementScreenState
    extends State<PymeOffersManagementScreen> {
  
  void _addOffer(Offer offer) {
    setState(() {
      OfferData.offers.add(offer);
    });
  }

  void _editOffer(Offer offer) {
    setState(() {
      final index = OfferData.offers.indexWhere((o) => o.id == offer.id);
      if (index != -1) {
        OfferData.offers[index] = offer;
      }
    });
  }

  void _deleteOffer(String id) {
    setState(() {
      OfferData.offers.removeWhere((o) => o.id == id);
    });
  }

  void _showOfferDialog({Offer? offer}) {
    final isEditing = offer != null;
    final titleController = TextEditingController(text: offer?.title ?? '');
    final descController = TextEditingController(text: offer?.description ?? '');
    
    // Valores por defecto para nueva oferta
    IconData selectedIcon = offer?.icon ?? Icons.local_offer;
    Color selectedColor = offer?.color ?? const Color(0xFF4ECDC4);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              isEditing ? 'Editar Oferta' : 'Nueva Oferta',
              style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF6B6B))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF6B6B))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Icono',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                        label: Icon(icon, size: 18, color: selectedIcon == icon ? Colors.white : Colors.black87),
                        selected: selectedIcon == icon,
                        selectedColor: selectedColor,
                        backgroundColor: Colors.grey[200],
                        onSelected: (bool selected) {
                          setStateDialog(() {
                            selectedIcon = icon;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      const Color(0xFF4ECDC4),
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFFD93D),
                      Colors.purpleAccent,
                      Colors.blueAccent,
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
                                ? Border.all(color: Colors.black87, width: 2)
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
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    final newOffer = Offer(
                      id: isEditing ? offer.id : DateTime.now().toString(),
                      title: titleController.text,
                      description: descController.text,
                      icon: selectedIcon,
                      color: selectedColor,
                    );
                    
                    if (isEditing) {
                      _editOffer(newOffer);
                    } else {
                      _addOffer(newOffer);
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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestión de Ofertas',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B6B),
        onPressed: () => _showOfferDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: OfferData.offers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ofertas activas',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: OfferData.offers.length,
              itemBuilder: (context, index) {
                final offer = OfferData.offers[index];
                return Dismissible(
                  key: Key(offer.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteOffer(offer.id),
                  child: Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: offer.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(offer.icon, color: offer.color),
                      ),
                      title: Text(
                        offer.title,
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          offer.description,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showOfferDialog(offer: offer),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}