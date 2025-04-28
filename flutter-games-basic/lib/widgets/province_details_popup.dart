import 'package:flutter/material.dart';
import '../models/game_types.dart';

class ProvinceDetailsPopup extends StatelessWidget {
  final Province province;
  final Nation? ownerNation;
  final Function(int, int)? onRecruitArmy;

  const ProvinceDetailsPopup({
    super.key,
    required this.province,
    required this.ownerNation,
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
      margin: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Province info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  province.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ownerNation != null) Row(
                    children: [
                      Image.asset(
                        'assets/flags/${ownerNation!.nationTag.toLowerCase()}.png',
                      width: 32,
                      height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ownerNation!.name,
                        style: const TextStyle(
                        fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Stats section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  emoji: '👥',
                  label: 'Population',
                  value: _formatNumber(province.population),
                ),
                _StatItem(
                  emoji: '💰',
                  label: 'Income',
                  value: _formatNumber(province.goldIncome),
                ),
                _StatItem(
                  emoji: '🏭',
                  label: 'Industry',
                  value: _formatNumber(province.industry),
                ),
                _StatItem(
                  emoji: '⚔️',
                  label: 'Army',
                  value: _formatNumber(province.army),
                ),
              ],
            ),
          ),
          // Resource and buildings section
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    transform: Matrix4.translationValues(0, -2, 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF67B9E7), // Light blue from reference
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF4792BA), // Darker blue from reference
                          offset: Offset(0, 4),
                          blurRadius: 0,
                ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Handle Info tap
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ℹ️',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Info',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    transform: Matrix4.translationValues(0, -2, 0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6EC53E), // Light green from reference
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF59A700), // Darker green from reference
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Handle Buildings tap
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🏛️',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buildings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ],
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

class _StatItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatItem({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
} 