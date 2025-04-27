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
    print('ResourceBar build');
    print('Nation: ${nation.name}');
    print('Gold: ${nation.gold}');
    print('Gold Income: ${nation.totalGoldIncome}');
    print('Population: ${nation.totalPopulation}');
    print('Industry: ${nation.totalIndustry}');
    print('Army: ${nation.totalArmy}');
    print('Resources: ${nation.resourceCounts}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            child: Column(
              children: [
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ResourceItem(
                  emoji: '💰',
                      value: _formatNumber(nation.gold),
                  suffix: '',
                ),
                    _ResourceItem(
                      emoji: '📈',
                      value: _formatNumber(nation.totalGoldIncome),
                      suffix: '/month',
                    ),
                _ResourceItem(
                  emoji: '👥',
                  value: _formatNumber(nation.totalPopulation),
                  suffix: '',
                ),
                    _ResourceItem(
                      emoji: '⚔️',
                      value: _formatNumber(nation.totalArmy),
                      suffix: '',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                _ResourceItem(
                  emoji: '🏭',
                  value: _formatNumber(nation.totalIndustry),
                  suffix: '',
                ),
                _ResourceItem(
                      emoji: '⛏️',
                      value: _formatNumber(nation.resourceCounts[ResourceType.coal] ?? 0),
                      suffix: 'coal',
                    ),
                    _ResourceItem(
                      emoji: '⚒️',
                      value: _formatNumber(nation.resourceCounts[ResourceType.iron] ?? 0),
                      suffix: 'iron',
                    ),
                    _ResourceItem(
                      emoji: '🌾',
                      value: _formatNumber(nation.resourceCounts[ResourceType.food] ?? 0),
                      suffix: 'food',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Row(
            children: [
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
                        boxShadow: [],
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