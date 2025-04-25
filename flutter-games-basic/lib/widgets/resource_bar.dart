import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/game_types.dart';

class ResourceBar extends StatelessWidget {
  final Nation nation;

  const ResourceBar({
    super.key,
    required this.nation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ResourceItem(
                icon: Icons.monetization_on,
                value: nation.gold.toString(),
                label: 'Gold',
              ),
              _ResourceItem(
                icon: Icons.attach_money,
                value: '${nation.totalGoldIncome}/month',
                label: 'Income',
              ),
              _ResourceItem(
                icon: Icons.factory,
                value: nation.totalIndustry.toString(),
                label: 'Industry',
              ),
              _ResourceItem(
                icon: Icons.science,
                value: nation.researchPoints.toString(),
                label: 'Research',
              ),
              _ResourceItem(
                icon: Icons.military_tech,
                value: nation.totalArmy.toString(),
                label: 'Army',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ResourceItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 