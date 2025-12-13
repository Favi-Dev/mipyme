import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupporterCounter extends StatelessWidget {
  final int count;
  final bool isSmall;

  const SupporterCounter({
    super.key,
    required this.count,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'S+',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: theme.colorScheme.primary,
              size: isSmall ? 32 : 40,
            ),
            Text(
              _formatCount(count),
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count > 999) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
