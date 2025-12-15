import 'package:flutter/material.dart';
import '../models/client_data.dart';

class ClientQrScreen extends StatelessWidget {
  const ClientQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Mi Cupón Mensual',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F3F2A).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              ClientData.isMonthlyCouponRedeemed ? 'Estado' : 'Valor del Cupón',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              ClientData.isMonthlyCouponRedeemed ? 'CANJEADO' : '\$10.000',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ClientData.isMonthlyCouponRedeemed 
                                    ? theme.colorScheme.outline 
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Placeholder for QR Code
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 250,
                                  height: 250,
                                  color: const Color(0xFFF4F1EA), // QR code background
                                  child: Center(
                                    child: Icon(
                                      Icons.qr_code_2,
                                      color: ClientData.isMonthlyCouponRedeemed 
                                          ? theme.colorScheme.outline.withOpacity(0.3) 
                                          : const Color(0xFF2F3F2A), // QR code color
                                      size: 150,
                                    ),
                                  ),
                                ),
                                if (ClientData.isMonthlyCouponRedeemed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
                                    ),
                                    child: Transform.rotate(
                                      angle: -0.2,
                                      child: Text(
                                        'UTILIZADO',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'CUPON-MENSUAL-NOV',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ClientData.isMonthlyCouponRedeemed 
                                    ? theme.colorScheme.outline 
                                    : theme.colorScheme.onSurface,
                                decoration: ClientData.isMonthlyCouponRedeemed ? TextDecoration.lineThrough : null,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ClientData.isMonthlyCouponRedeemed 
                                  ? 'Este cupón ya ha sido utilizado este mes'
                                  : 'Muestra este código para descontar \$10.000',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, color: theme.colorScheme.onPrimaryContainer),
                            const SizedBox(width: 10),
                            Text(
                              'Válido hasta 30 Nov',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
