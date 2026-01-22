import 'package:flutter/material.dart';

class Offer {
  String id;
  String title;
  String description;
  IconData icon;
  Color color;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.local_offer.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      color: Color(map['colorValue'] ?? 0xFF000000),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
    };
  }
}

// Simple in-memory storage for prototype
class OfferData {
  static List<Offer> offers = [
    Offer(
      id: '1',
      title: 'Exclusivo App SoyPlus',
      description: '20% dcto. en Botas de Cuero',
      icon: Icons.star,
      color: const Color(0xFF2F3F2A), // Verde Hoja Profundo
    ),
    Offer(
      id: '2',
      title: 'Promo del Mes',
      description: 'Limpieza de calzado gratis',
      icon: Icons.local_offer,
      color: const Color(0xFF6F8F5E), // Verde Claro
    ),
  ];

  static void loadOffersForCategory(String category) {
    offers.clear();
    switch (category) {
      case 'Comercio/retail':
        offers.addAll([
          Offer(
            id: '1',
            title: 'Exclusivo App SoyPlus',
            description: '20% dcto. en Botas de Cuero',
            icon: Icons.star,
            color: const Color(0xFF2F3F2A),
          ),
          Offer(
            id: '2',
            title: 'Promo del Mes',
            description: 'Limpieza de calzado gratis',
            icon: Icons.local_offer,
            color: const Color(0xFF6F8F5E),
          ),
        ]);
        break;
      case 'Alimentos y gastronomía':
        offers.addAll([
          Offer(
            id: '3',
            title: 'Exclusivo App SoyPlus',
            description: '2x1 en Cappuccinos (Lun-Mie)',
            icon: Icons.coffee,
            color: const Color(0xFF8B5A3C),
          ),
          Offer(
            id: '4',
            title: 'Descuento Dulce',
            description: '15% dcto. en Tortas enteras',
            icon: Icons.cake,
            color: const Color(0xFFE3B58F),
          ),
        ]);
        break;
      case 'Servicios profesionales':
        offers.addAll([
          Offer(
            id: '5',
            title: 'Exclusivo App SoyPlus',
            description: 'Primera consulta gratis',
            icon: Icons.work,
            color: const Color(0xFF2F3F2A),
          ),
        ]);
        break;
      case 'Salud, belleza y bienestar':
        offers.addAll([
          Offer(
            id: '6',
            title: 'Exclusivo App SoyPlus',
            description: '10% dcto. en Vitaminas',
            icon: Icons.health_and_safety,
            color: const Color(0xFF6F8F5E),
          ),
        ]);
        break;
      case 'Oficios y manufactura':
        offers.addAll([
          Offer(
            id: '7',
            title: 'Exclusivo App SoyPlus',
            description: 'Barnizado gratis por compra de mesa',
            icon: Icons.handyman,
            color: const Color(0xFF8B5A3C),
          ),
        ]);
        break;
      case 'Educación y cultura':
        offers.addAll([
          Offer(
            id: '8',
            title: 'Beneficio SoyPlus',
            description: 'Entrada liberada a charla mensual',
            icon: Icons.school,
            color: const Color(0xFF2F3F2A),
          ),
        ]);
        break;
      case 'Transporte y logística':
        offers.addAll([
          Offer(
            id: '9',
            title: 'Exclusivo App SoyPlus',
            description: '5% dcto. en mudanzas programadas',
            icon: Icons.local_shipping,
            color: const Color(0xFF2F3F2A),
          ),
        ]);
        break;
      case 'Metamorfosis':
        offers.addAll([
          Offer(
            id: '10',
            title: 'Exclusivo App SoyPlus',
            description: 'Personalización gratis en tu primera compra',
            icon: Icons.auto_fix_high,
            color: const Color(0xFF6F8F5E),
          ),
        ]);
        break;
      default:
        offers.addAll([
          Offer(
            id: '1',
            title: 'Exclusivo App SoyPlus',
            description: 'Descuento especial para usuarios',
            icon: Icons.star,
            color: const Color(0xFF2F3F2A),
          ),
        ]);
    }
  }
}
