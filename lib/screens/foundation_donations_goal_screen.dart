import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pyme_service.dart';

class FoundationDonationsGoalScreen extends StatefulWidget {
  const FoundationDonationsGoalScreen({super.key});

  @override
  State<FoundationDonationsGoalScreen> createState() => _FoundationDonationsGoalScreenState();
}

class _FoundationDonationsGoalScreenState extends State<FoundationDonationsGoalScreen> {
  final TextEditingController _goalController = TextEditingController();
  final PymeService _pymeService = PymeService();
  final String _currentPymeId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isEditing = false;
  double _currentGoal = 0;
  double _currentTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final metrics = await _pymeService.getPymeMetrics(_currentPymeId).first;
    // Assuming metrics contains 'totalSales' which is donations for foundations
    setState(() {
      _currentTotal = (metrics['totalSales'] as num?)?.toDouble() ?? 0.0;
    });

    // Load Goal from Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentPymeId).get();
    if (userDoc.exists) {
      if (mounted) {
        setState(() {
          _currentGoal = (userDoc.data()?['fundraisingGoal'] as num?)?.toDouble() ?? 0.0;
          _goalController.text = _currentGoal.toStringAsFixed(0);
        });
      }
    }
  }

  Future<void> _updateGoal() async {
    final newGoal = double.tryParse(_goalController.text) ?? 0.0;
    
    await FirebaseFirestore.instance.collection('users').doc(_currentPymeId).set({
      'fundraisingGoal': newGoal
    }, SetOptions(merge: true));

    setState(() {
      _currentGoal = newGoal;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta actualizada correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentGoal > 0 ? (_currentTotal / _currentGoal) : 0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text('Meta de Recaudación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Setting Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        'Mi Meta',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2F3F2A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isEditing ? Icons.close : Icons.edit, color: const Color(0xFF6F8F5E)),
                        onPressed: () {
                          setState(() => _isEditing = !_isEditing);
                        },
                      ),
                    ],
                   ),
                   const SizedBox(height: 16),
                   if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _goalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monto Meta',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                         const SizedBox(width: 12),
                         ElevatedButton(
                           onPressed: _updateGoal,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF6F8F5E),
                             foregroundColor: Colors.white,
                           ),
                           child: const Text('Guardar'),
                         ),
                      ],
                    )
                   else
                     Column(
                       children: [
                         Text(
                           '\$${_currentGoal.toStringAsFixed(0)}',
                           style: GoogleFonts.poppins(
                             fontSize: 36,
                             fontWeight: FontWeight.bold,
                             color: const Color(0xFF2F3F2A),
                           ),
                         ),
                         Text(
                          'Objetivo Total',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                         ),
                       ],
                     ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Progress Section
            Text(
              'Progreso Actual',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F3F2A),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3F2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recaudado',
                            style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA).withOpacity(0.7)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_currentTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF4F1EA)
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8F5E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6F8F5E)),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Las donaciones ayudan a financiar talleres y capacitaciones para adultos mayores.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF4F1EA).withOpacity(0.6),
                      fontSize: 12,
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
}
