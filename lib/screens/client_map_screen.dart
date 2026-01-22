import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'client_pyme_detail_screen.dart';
import '../services/pyme_service.dart';
import '../models/user_profile.dart';
import 'dart:math';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({super.key});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  final PymeService _pymeService = PymeService();
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(-33.4489, -70.6693); // Santiago default
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _hasLocation = true;
        });
        _mapController.move(_currentLocation, 15.0);
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  // Helper to generate deterministic position based on ID around current location
  LatLng _getPosition(String id) {
    final hash = id.hashCode;
    final random = Random(hash);
    // Generate random offset within ~2km
    final latOffset = (random.nextDouble() - 0.5) * 0.04;
    final lngOffset = (random.nextDouble() - 0.5) * 0.04;
    
    // Use Santiago center as base if no user location, otherwise user location
    // This ensures pins are always visible near the "center" of action
    final base = _hasLocation ? _currentLocation : const LatLng(-33.4489, -70.6693);
    
    return LatLng(base.latitude + latOffset, base.longitude + lngOffset);
  }

  // Helper to get style based on category
  Map<String, dynamic> _getStyleForCategory(String? category) {
    switch (category) {
      case 'Comercio/retail':
        return {'icon': Icons.shopping_bag, 'color': const Color(0xFF8D6E63)};
      case 'Alimentos y gastronomía':
        return {'icon': Icons.restaurant, 'color': Colors.orange};
      case 'Servicios profesionales':
        return {'icon': Icons.business_center, 'color': Colors.blueGrey};
      case 'Salud, belleza y bienestar':
        return {'icon': Icons.medical_services, 'color': const Color(0xFFE63946)};
      case 'Oficios y manufactura':
        return {'icon': Icons.handyman, 'color': Colors.brown};
      case 'Educación y cultura':
        return {'icon': Icons.school, 'color': const Color(0xFF0056D2)};
      case 'Transporte y logistica':
        return {'icon': Icons.local_shipping, 'color': Colors.indigo};
      default:
        return {'icon': Icons.store, 'color': Colors.teal};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Widget
          StreamBuilder<List<UserProfile>>(
            stream: _pymeService.getAllPublicProfiles(),
            builder: (context, snapshot) {
              final pymes = snapshot.data ?? [];
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mipyme',
                  ),
                  MarkerLayer(
                    markers: [
                      // User Location Marker
                      if (_hasLocation)
                        Marker(
                          point: _currentLocation,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                            ),
                            child: Icon(
                              Icons.my_location,
                              color: theme.colorScheme.primary,
                              size: 30,
                            ),
                          ),
                        ),
                      
                      // Pyme Markers
                      ...pymes.map((pyme) {
                        LatLng pos;
                        if (pyme.latitude != null && pyme.longitude != null) {
                          pos = LatLng(pyme.latitude!, pyme.longitude!);
                        } else {
                          pos = _getPosition(pyme.id);
                        }

                        final style = _getStyleForCategory(pyme.category);
                        
                        return Marker(
                          point: pos,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showPymePreview(context, pyme, style),
                            child: Container(
                              decoration: BoxDecoration(
                                color: style['color'],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                style['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
          
          // 2. Search Bar Overlay
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F3F2A).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar en el mapa...',
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_hasLocation) {
            _mapController.move(_currentLocation, 15.0);
          } else {
            _checkLocationPermission();
          }
        },
        backgroundColor: theme.colorScheme.surface,
        child: Icon(Icons.my_location, color: theme.colorScheme.primary),
      ),
    );
  }

  void _showPymePreview(BuildContext context, UserProfile pyme, Map<String, dynamic> style) {
    final theme = Theme.of(context);
    final name = pyme.name;
    final category = pyme.category ?? 'Sin categoría';
    final image = pyme.coverImageUrl;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F3F2A).withOpacity(0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: (image != null && image.startsWith('http'))
                        ? NetworkImage(image)
                        : AssetImage(image ?? 'assets/images/placeholder.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                category,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  _navigateToPymeDetail(context, pyme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToPymeDetail(context, pyme);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Ver Perfil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPymeDetail(BuildContext context, UserProfile pyme) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientPymeDetailScreen(
          pymeId: pyme.id,
          pymeData: pyme,
        ),
      ),
    );
  }
}
