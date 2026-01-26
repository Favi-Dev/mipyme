import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/client_service.dart';


class ClientQrScreen extends StatefulWidget {
  const ClientQrScreen({super.key});

  @override
  State<ClientQrScreen> createState() => _ClientQrScreenState();
}

class _ClientQrScreenState extends State<ClientQrScreen> {
  final ClientService _clientService = ClientService();

  @override
  void initState() {
    super.initState();
    _clientService.checkAndResetMonthlyCoupon();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = _clientService.currentUserId;
    
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
      body: StreamBuilder<DateTime?>(
        stream: _clientService.getSubscriptionDate(),
        builder: (context, dateSnapshot) {
          final subscriptionDate = dateSnapshot.data;
          
          // Check if in first month delay
          if (subscriptionDate != null) {
            final firstCouponDate = DateTime(
              subscriptionDate.year, 
              subscriptionDate.month + 1, 
              subscriptionDate.day
            );
            
            if (DateTime.now().isBefore(firstCouponDate)) {
              return _buildLockedView(theme, firstCouponDate);
            }
          }

          return StreamBuilder<bool>(
            stream: _clientService.getMonthlyCouponStatus(),
            builder: (context, couponSnapshot) {
              final isRedeemed = couponSnapshot.data ?? false;
              return _buildCouponView(theme, isRedeemed, userId);
            },
          );
        }
      ),
    );
  }



  Widget _buildLockedView(ThemeData theme, DateTime unlockDate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Cupón en Espera',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu primer cupón estará disponible un mes después de tu suscripción.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Disponible desde:', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${unlockDate.day}/${unlockDate.month}/${unlockDate.year}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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

  Widget _buildCouponView(ThemeData theme, bool isRedeemed, String? userId) {
    return LayoutBuilder(
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
                            isRedeemed ? 'Estado' : 'Valor del Cupón',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            isRedeemed ? 'CANJEADO' : '\$10.000',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isRedeemed 
                                  ? theme.colorScheme.outline 
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: isRedeemed
                                  ? Icon(
                                      Icons.check_circle_outline,
                                      size: 100,
                                      color: theme.colorScheme.outline.withOpacity(0.5),
                                    )
                                  : QrImageView(
                                      data: userId ?? 'error',
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      foregroundColor: const Color(0xFF2F3F2A),
                                    ),
                            ),
                          ),
                          if (isRedeemed)
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
                              ),
                              child: Transform.rotate(
                                angle: -0.2,
                                child: Text(
                                  'CANJEADO',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        isRedeemed
                            ? 'Este cupón ya fue utilizado este mes. Vuelve el próximo mes para obtener uno nuevo.'
                            : 'Presenta este código QR en cualquier Pyme asociada para obtener tu descuento.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
