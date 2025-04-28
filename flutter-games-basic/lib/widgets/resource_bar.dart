import 'package:flutter/material.dart';
import '../models/game_types.dart';

class ResourceBar extends StatelessWidget {
  final Nation nation;
  final List<Province> provinces;

  const ResourceBar({
    super.key,
    required this.nation,
    required this.provinces,
  });

  String _formatNumber(num number) {
    if (number == 0) return "0";
    
    bool isNegative = number < 0;
    number = number.abs();
    
    final suffixes = ["", "k", "m", "b", "t"];
    
    int suffixIndex = 0;
    while (number >= 1000 && suffixIndex < suffixes.length - 1) {
      number /= 1000;
      suffixIndex++;
    }
    
    String formatted;
    if (number >= 100) {
      formatted = number.round().toString();
    } else if (number >= 10) {
      formatted = number.toStringAsFixed(1);
      if (formatted.endsWith('.0')) {
        formatted = formatted.substring(0, formatted.length - 2);
      }
    } else {
      formatted = number.toStringAsFixed(2);
      if (formatted.endsWith('0')) {
        formatted = formatted.substring(0, formatted.length - 1);
        if (formatted.endsWith('.0')) {
          formatted = formatted.substring(0, formatted.length - 2);
        }
      }
    }
    
    return (isNegative ? "-" : "") + formatted + suffixes[suffixIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              value: _formatNumber(nation.gold),
              suffix: '',
            ),
            _ResourceItem(
              emoji: '👥',
              value: _formatNumber(nation.getTotalPopulation(provinces)),
              suffix: '',
            ),
            _ResourceItem(
              emoji: '🏭',
              value: _formatNumber(nation.getTotalIndustry(provinces)),
              suffix: '',
            ),
            _ResourceItem(
              emoji: '⚔️',
              value: _formatNumber(nation.getTotalArmy(provinces)),
              suffix: '',
            ),
          ],
        ),
      ),
    );
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