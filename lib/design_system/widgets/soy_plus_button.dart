import 'package:flutter/material.dart';

class SoyPlusButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final double width;

  const SoyPlusButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : theme.colorScheme.primary,
          foregroundColor: isSecondary ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
          elevation: isSecondary ? 0 : 2,
          shadowColor: isSecondary ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary ? BorderSide(color: theme.colorScheme.primary) : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSecondary ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
