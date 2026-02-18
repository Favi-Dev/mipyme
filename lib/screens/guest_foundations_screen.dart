import 'package:flutter/material.dart';
import 'package:mipyme/services/pyme_service.dart';
import 'package:mipyme/models/user_profile.dart';
import 'package:mipyme/screens/donation_screen.dart';

class GuestFoundationsScreen extends StatelessWidget {
  const GuestFoundationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final PymeService pymeService = PymeService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundaciones Disponibles'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: pymeService.getFoundations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foundations = snapshot.data!;

          if (foundations.isEmpty) {
            return const Center(child: Text('No hay fundaciones disponibles por el momento.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: foundations.length,
            itemBuilder: (context, index) {
              final foundation = foundations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DonationScreen(
                          isGuest: true,
                          preSelectedFoundation: foundation,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (foundation.coverImageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            foundation.coverImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 50),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundation.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (foundation.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                foundation.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DonationScreen(
                                        isGuest: true,
                                        preSelectedFoundation: foundation,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.volunteer_activism),
                                label: const Text('Donar Ahora'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: theme.colorScheme.onSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
