import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/pyme_service.dart';

class PymeValidationScannerScreen extends StatefulWidget {
  const PymeValidationScannerScreen({super.key});

  @override
  State<PymeValidationScannerScreen> createState() =>
      _PymeValidationScannerScreenState();
}

class _PymeValidationScannerScreenState
    extends State<PymeValidationScannerScreen>
    with SingleTickerProviderStateMixin {
  final PymeService _pymeService = PymeService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _validateCode(barcode.rawValue!);
        break; // Process only the first code
      }
    }
  }

  Future<void> _validateCode(String userId) async {
    setState(() {
      _isProcessing = true;
      _isScanning = false; // Pause scanning
    });

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final userData = await _pymeService.getUserById(userId);
      
      Navigator.pop(context); // Close loading

      if (userData == null) {
        _showResultDialog(false, 'Usuario no encontrado', 'El código QR no corresponde a un usuario válido.');
        return;
      }

      final isSubscribed = userData['isSubscribed'] ?? false;
      final isRedeemed = userData['monthlyCouponRedeemed'] ?? false;

      if (!isSubscribed) {
        _showResultDialog(false, 'Sin Suscripción', 'El cliente no tiene una suscripción activa.');
        return;
      }

      if (isRedeemed) {
        _showResultDialog(false, 'Cupón Canjeado', 'Este cliente ya utilizó su cupón de este mes.');
        return;
      }

      _showConfirmationDialog(userId, userData['name'] ?? 'Cliente');

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        _showResultDialog(false, 'Error', 'Ocurrió un error al validar: $e');
      }
    }
  }

  void _showConfirmationDialog(String userId, String clientName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4F1EA),
        title: Text('Confirmar Canje', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: $clientName',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Desea aplicar el descuento de \$10.000?',
              style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción consumirá el cupón mensual del cliente.',
              style: GoogleFonts.poppins(color: const Color(0xFF6F8F5E), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRedemption(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F8F5E)),
            child: Text('Confirmar', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processRedemption(String userId) async {
    try {
      await _pymeService.redeemCouponForUser(userId);
      _showResultDialog(true, '¡Éxito!', 'El cupón ha sido canjeado correctamente.');
    } catch (e) {
      _showResultDialog(false, 'Error', 'No se pudo canjear el cupón: $e');
    }
  }

  void _showResultDialog(bool success, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4F1EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? const Color(0xFF6F8F5E) : const Color(0xFF8B5A3C),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F3F2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3F2A),
                  foregroundColor: const Color(0xFFF4F1EA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Volver a Escanear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Validar Cupón', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF6F8F5E),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Escanea el código QR del cliente',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for overlay (simplified version of what usually comes with scanner packages or custom)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              cutOutRect,
              Radius.circular(borderRadius),
            ),
          ),
      ),
      backgroundPaint,
    );

    // Draw corners
    final r = cutOutRect;
    final bl = borderLength;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + bl)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + bl, r.top),
      borderPaint,
    );
    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(r.right - bl, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + bl),
      borderPaint,
    );
    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(r.right, r.bottom - bl)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right - bl, r.bottom),
      borderPaint,
    );
    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(r.left + bl, r.bottom)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left, r.bottom - bl),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
