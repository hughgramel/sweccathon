import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_types.dart';
import '../data/world_1914.dart';

/// Screen that displays the list of playable nations in the 1914 scenario
class CountryList1914Screen extends StatelessWidget {
  const CountryList1914Screen({super.key});

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
              itemCount: world1914.nations.length,
              itemBuilder: (context, index) {
                final nation = world1914.nations[index];
                return _NationCard(
                  nation: nation,
                  onTap: () => context.go('/game-view/${nation.nationTag}'),
                );
              },
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

class _NationCard extends StatelessWidget {
  final Nation nation;
  final VoidCallback onTap;

  const _NationCard({
    required this.nation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            // Nation name
            Row(
              children: [
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(nation.hexColor.substring(1), radix: 16) | 0xFF000000),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Statistics grid
            Row(
              children: [
                _StatItem(
                  icon: Icons.people_outline,
                  value: '${(nation.getTotalPopulation(world1914.provinces) / 1000000).toStringAsFixed(1)}M',
                  label: 'Population',
                ),
                _StatItem(
                  icon: Icons.factory_outlined,
                  value: nation.getTotalIndustry(world1914.provinces).toString(),
                  label: 'Industry',
                ),
                _StatItem(
                  icon: Icons.monetization_on_outlined,
                  value: nation.gold.toString(),
                  label: 'Gold',
                ),
                _StatItem(
                  icon: Icons.military_tech_outlined,
                  value: nation.getTotalArmy(world1914.provinces).toString(),
                  label: 'Army',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.mPlusRounded1c(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.mPlusRounded1c(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 