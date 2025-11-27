import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/client_data.dart';

class PymeValidationScannerScreen extends StatefulWidget {
  const PymeValidationScannerScreen({super.key});

  @override
  State<PymeValidationScannerScreen> createState() =>
      _PymeValidationScannerScreenState();
}

class _PymeValidationScannerScreenState
    extends State<PymeValidationScannerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _validateCode(String code) {
    // Simulate network delay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Close loading
      if (mounted) {
        setState(() {
          _isScanning = false;
          _animationController.stop();
        });

        // Simulate valid code check
        // In a real app, this would check against a backend
        bool isValidCode = code.isNotEmpty; 

        if (!isValidCode) {
          _showResultDialog(false, code, 'Código inválido');
          return;
        }

        if (!ClientData.hasActiveSubscription) {
           _showResultDialog(false, code, 'Cliente sin suscripción activa');
           return;
        }

        if (ClientData.isMonthlyCouponRedeemed) {
           _showResultDialog(false, code, 'Este cupón ya fue utilizado este mes.');
           return;
        }

        _showConfirmationDialog(code);
      }
    });
  }

  void _showConfirmationDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Confirmar Canje', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Desea aplicar el descuento de \$10.000?',
              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción consumirá el cupón mensual del cliente.',
              style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Redeem coupon
              setState(() {
                ClientData.isMonthlyCouponRedeemed = true;
                ClientData.couponAmount = 0; // Set balance to 0
              });
              Navigator.pop(context);
              _showResultDialog(true, code, 'Descuento de \$10.000 aplicado correctamente.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(bool success, String code, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? '¡Validación Exitosa!' : 'Error',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                _codeController.clear();
              }
            },
            child: const Text('Aceptar', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Validar Cupón Mensual',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Escanea el QR mensual del cliente',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Scanner UI Simulation
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Camera placeholder pattern
                          Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 200,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          // Scanning line animation
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Positioned(
                                top: _animation.value * 260,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B6B).withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Corner markers
                          ..._buildCornerMarkers(),
                        ],
                      ),
                    ),
                  ),
                  if (!_isScanning)
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.play_circle_fill,
                              size: 64, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isScanning = true;
                              _animationController.repeat(reverse: true);
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isScanning = !_isScanning;
                    if (_isScanning) {
                      _animationController.repeat(reverse: true);
                    } else {
                      _animationController.stop();
                    }
                  });
                },
                icon: Icon(
                  _isScanning ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFFFF6B6B),
                ),
                label: Text(
                  _isScanning ? 'Pausar Escáner' : 'Activar Escáner',
                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey[300]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O ingresa el código',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey[300]),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.black87, fontSize: 18),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'EJ: CUPON-NOV',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
                  ),
                  prefixIcon: const Icon(Icons.keyboard, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_codeController.text.isNotEmpty) {
                      _validateCode(_codeController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Validar Cupón',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _validateCode('PRO123'); // Simulate successful scan
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFFF6B6B)),
                  label: const Text(
                    'Simular Escaneo Exitoso',
                    style: TextStyle(color: Color(0xFFFF6B6B)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF6B6B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const double size = 40;
    const double thickness = 4;
    const Color color = Color(0xFFFF6B6B);

    return [
      // Top Left
      Positioned(
        top: 20,
        left: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: 20,
        right: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 20,
        left: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 20,
        right: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }
}