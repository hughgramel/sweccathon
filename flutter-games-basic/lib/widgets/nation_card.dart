import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/nation.dart';

/// A card widget that displays a nation's information and statistics
class NationCard extends StatelessWidget {
  /// The nation to display
  final Nation nation;

  const NationCard({
    super.key,
    required this.nation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nation name and difficulty
          Row(
            children: [
              Text(
                nation.flag,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                nation.name,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: nation.difficulty == NationDifficulty.easy
                      ? const Color(0xFFE7F5EC)  // Light green
                      : const Color(0xFFFFF8E1), // Light yellow
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  nation.difficulty == NationDifficulty.easy ? 'Easy' : 'Medium',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: nation.difficulty == NationDifficulty.easy
                        ? const Color(0xFF2E7D32)  // Dark green
                        : const Color(0xFFFFA000), // Dark yellow
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Statistics grid
          Row(
            children: [
              // Population and Industry
              Expanded(
                child: Row(
                  children: [
                    // Population
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.people_outline, size: 20, color: Colors.black54),
                          const SizedBox(height: 4),
                          Text(
                            '${nation.population}M',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Industry
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.factory_outlined, size: 20, color: Colors.black54),
                          const SizedBox(height: 4),
                          Text(
                            '${nation.industry}M',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Gold and Army
              Expanded(
                child: Row(
                  children: [
                    // Gold
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.monetization_on_outlined, size: 20, color: Colors.black54),
                          const SizedBox(height: 4),
                          Text(
                            '${nation.gold}M',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Army
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.military_tech_outlined, size: 20, color: Colors.black54),
                          const SizedBox(height: 4),
                          Text(
                            '${nation.army}M',
                            style: GoogleFonts.mPlusRounded1c(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 