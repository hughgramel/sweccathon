import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/game_types.dart';
import 'dart:math';

class ResourceBar extends StatelessWidget {
  final Nation nation;

  const ResourceBar({
    super.key,
    required this.nation,
  });

  String _formatNumber(num value) {
    // First convert to 3 significant digits
    final preciseValue = value.toPrecision(3);
    
    if (preciseValue >= 1000000) {
      return '${(preciseValue / 1000000).toPrecision(3)}M';
    } else if (preciseValue >= 1000) {
      return '${(preciseValue / 1000).toPrecision(3)}K';
    }
    return preciseValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resource bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration( 
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ResourceItem(
                  emoji: '💰',
                  value: _formatNumber(nation.totalGoldIncome),
                  suffix: '',
                ),
                _ResourceItem(
                  emoji: '👥',
                  value: _formatNumber(nation.totalPopulation),
                  suffix: '',
                ),
                _ResourceItem(
                  emoji: '🏭',
                  value: _formatNumber(nation.totalIndustry),
                  suffix: '',
                ),
                _ResourceItem(
                  emoji: '⚔️',
                  value: _formatNumber(nation.totalArmy),
                  suffix: '',
                ),
              ],
            ),
          ),
        ),
        // Flag and date row
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Row(
            children: [
              // Flag
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/flags/${nation.nationTag.toLowerCase()}.png',
                      width: 40,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                        ],
                      ),
                      child: const Text(
                        'Jan 1, 1836',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension NumPrecision on num {
  double toPrecision(int precision) {
    if (this == 0) return 0;
    final String str = this.toString();
    final List<String> parts = str.split('.');
    if (parts.length == 1) return this.toDouble();
    
    final String digitsStr = parts.join('');
    final int nonZeroIndex = digitsStr.indexOf(RegExp(r'[1-9]'));
    final String significantDigits = digitsStr.substring(nonZeroIndex, nonZeroIndex + precision);
    final double result = double.parse(significantDigits) * pow(10, nonZeroIndex - significantDigits.length + 1);
    return result;
  }
}

class _ResourceItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String suffix;

  const _ResourceItem({
    required this.emoji,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          '$value$suffix',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
} 