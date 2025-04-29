import 'package:flutter/material.dart';
import '../models/game_types.dart';

class ProvinceDetailsPopup extends StatelessWidget {
  final Province province;
  final Nation? ownerNation;
  final Game game;
  final VoidCallback onClose;

  const ProvinceDetailsPopup({
    super.key,
    required this.province,
    required this.ownerNation,
    required this.game,
    required this.onClose,
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
    final canSeeArmy = province.owner == game.playerNationTag || 
      game.playerNation.nationProvinces.any((playerProvinceId) {
        final playerProvince = game.provinces.firstWhere(
          (p) => p.id == playerProvinceId,
          orElse: () => Province(
            id: '',
            name: '',
            path: '',
            population: 0,
            goldIncome: 0,
            industry: 0,
            buildings: [],
            resourceType: ResourceType.none,
            armies: [],
            owner: '',
            borderingProvinces: [],
          ),
        );
        return playerProvince.borderingProvinces.contains(province.id);
      });

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            const SizedBox(height: 16),
            if (ownerNation != null) ...[
                          Text(
                'Owner: ${ownerNation!.name}',
                            style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                            ),
                          ),
              const SizedBox(height: 8),
            ],
            Text(
              'Population: ${province.population}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
                                  Text(
              'Gold Income: ${province.goldIncome}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                                    ),
                                  ),
            const SizedBox(height: 8),
                                  Text(
              'Industry: ${province.industry}',
              style: const TextStyle(
                                      fontSize: 16,
                color: Colors.black87,
                                    ),
                                  ),
            const SizedBox(height: 8),
            if (canSeeArmy) ...[
              Text(
                'Army: ${province.armies.fold(0, (sum, army) => sum + army.size)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
            ],
                                  Text(
              'Resource: ${province.resourceType.toString().split('.').last}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                                    ),
                                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    'Close',
                                    style: TextStyle(
                                      fontSize: 16,
                      color: Colors.black54,
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