import 'package:flutter/material.dart';
import '../models/game_types.dart';

class ProvinceDetailsPopup extends StatelessWidget {
  final Province province;
  final Nation? ownerNation;
  final Function(int armyChange, int industryChange)? onRecruitArmy;

  const ProvinceDetailsPopup({
    super.key,
    required this.province,
    this.ownerNation,
    this.onRecruitArmy,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  province.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ownerNation != null)
                  Row(
                    children: [
                      Image.asset(
                        'assets/flags/${ownerNation!.nationTag.toLowerCase()}.png',
                        width: 24,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ownerNation!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DetailItem(
                  emoji: '👥',
                  value: _formatNumber(province.population),
                  label: 'Population',
                ),
                _DetailItem(
                  emoji: '💰',
                  value: _formatNumber(province.goldIncome),
                  label: 'Income',
                ),
                _DetailItem(
                  emoji: '🏭',
                  value: _formatNumber(province.industry),
                  label: 'Industry',
                ),
                _DetailItem(
                  emoji: '⚔️',
                  value: _formatNumber(province.army),
                  label: 'Army',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DetailItem(
                  emoji: _getResourceEmoji(province.resourceType),
                  value: province.resourceType.toString().split('.').last,
                  label: 'Resource',
                ),
                _DetailItem(
                  emoji: '🏛️',
                  value: province.buildings.length.toString(),
                  label: 'Buildings',
                ),
                if (onRecruitArmy != null && province.industry >= 10)
                  TextButton.icon(
                    onPressed: () => onRecruitArmy!(5000, -10),
                    icon: const Text('⚔️', style: TextStyle(fontSize: 16)),
                    label: const Text(
                      'Recruit Army\n(-10 Industry)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getResourceEmoji(ResourceType type) {
    switch (type) {
      case ResourceType.gold:
        return '💰';
      case ResourceType.coal:
        return '⛏️';
      case ResourceType.iron:
        return '⚒️';
      case ResourceType.food:
        return '🌾';
      case ResourceType.none:
        return '❌';
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _DetailItem({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
} 