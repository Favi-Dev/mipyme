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
}

// Simple in-memory storage for prototype
class OfferData {
  static final List<Offer> offers = [
    Offer(
      id: '1',
      title: 'Exclusivo App Soy Pro',
      description: '20% dcto. en Botas de Cuero',
      icon: Icons.star,
      color: Colors.blueAccent,
    ),
    Offer(
      id: '2',
      title: 'Promo del Mes',
      description: 'Limpieza de calzado gratis',
      icon: Icons.local_offer,
      color: Colors.orangeAccent,
    ),
  ];
}
