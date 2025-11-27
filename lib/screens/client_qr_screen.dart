import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/client_data.dart';

class ClientQrScreen extends StatelessWidget {
  const ClientQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mi Cupón Mensual',
          style: GoogleFonts.poppins(
            color: Colors.black87,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    ClientData.isMonthlyCouponRedeemed ? 'Estado' : 'Valor del Cupón',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    ClientData.isMonthlyCouponRedeemed ? 'CANJEADO' : '\$10.000',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ClientData.isMonthlyCouponRedeemed ? Colors.grey : const Color(0xFFFF6B6B),
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
                        color: Colors.white,
                        child: Center(
                          child: Icon(
                            Icons.qr_code_2,
                            color: ClientData.isMonthlyCouponRedeemed ? Colors.grey[300] : Colors.black,
                            size: 150,
                          ),
                        ),
                      ),
                      if (ClientData.isMonthlyCouponRedeemed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Text(
                              'UTILIZADO',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
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
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ClientData.isMonthlyCouponRedeemed ? Colors.grey : Colors.black87,
                      decoration: ClientData.isMonthlyCouponRedeemed ? TextDecoration.lineThrough : null,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ClientData.isMonthlyCouponRedeemed 
                        ? 'Este cupón ya ha sido utilizado este mes'
                        : 'Muestra este código para descontar \$10.000',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFFFF6B6B)),
                  const SizedBox(width: 10),
                  Text(
                    'Válido hasta 30 Nov',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF6B6B),
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
