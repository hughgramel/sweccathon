import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/nation.dart';
import '../widgets/nation_card.dart';

/// Screen that displays the list of playable nations in the 1836 scenario
class CountryList1836Screen extends StatelessWidget {
  const CountryList1836Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Age of Focus',
          style: GoogleFonts.mPlusRounded1c(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/scenarios'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: nations1836.length,
              itemBuilder: (context, index) => NationCard(
                nation: nations1836[index],
              ),
            ),
          ),
          // Return to Scenarios button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextButton(
              onPressed: () => context.go('/scenarios'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF67B7F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Return to Scenarios',
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 