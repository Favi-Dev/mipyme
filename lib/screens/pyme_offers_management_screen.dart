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
    Color selectedColor = offer?.color ?? const Color(0xFF6F8F5E);

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
      body: OfferData.offers.isEmpty
          ? Center(
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
                    color: const Color(0xFF8B5A3C),
                    child: const Icon(Icons.delete, color: Color(0xFFF4F1EA)),
                  ),
                  onDismissed: (direction) => _deleteOffer(offer.id),
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
                          color: offer.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(offer.icon, color: offer.color),
                      ),
                      title: Text(
                        offer.title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F3F2A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          offer.description,
                          style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
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
