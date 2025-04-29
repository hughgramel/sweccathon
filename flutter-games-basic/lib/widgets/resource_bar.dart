import 'package:flutter/material.dart';
import '../models/game_types.dart';

class ResourceBar extends StatelessWidget {
  final Nation nation;
  final List<Province> provinces;
  final Game game;
  
  // Cache the formatted numbers to avoid recalculating them
  late final String _formattedGold = _formatNumber(nation.gold);
  late final String _formattedPopulation = _formatNumber(nation.getTotalPopulation(provinces));
  late final String _formattedIndustry = _formatNumber(nation.getTotalIndustry(provinces));
  late final String _formattedArmyReserve = _formatNumber(nation.armyReserve);
  
  // Cache the gains since they only update monthly
  late final ResourceGains _gains = game.getResourceGains(nation.nationTag);
  late final String _formattedGoldGain = _formatNumber(_gains.goldGain, forGain: true);
  late final String _formattedPopulationGain = _formatNumber(_gains.populationGain, forGain: true);
  late final String _formattedArmyGain = _formatNumber(_gains.armyGain, forGain: true);

  ResourceBar({
    super.key,
    required this.nation,
    required this.provinces,
    required this.game,
  });

  String _formatNumber(num number, {bool forGain = false}) {
    if (number == 0) return forGain ? "0.00" : "0";
    
    bool isNegative = number < 0;
    number = number.abs();
    
    final suffixes = ["", "k", "m", "b", "t"];
    
    int suffixIndex = 0;
    while (number >= 1000 && suffixIndex < suffixes.length - 1) {
      number /= 1000;
      suffixIndex++;
    }
    
    String formatted;
    if (forGain) {
      formatted = number.toStringAsFixed(2);
      if (formatted.contains('.') && formatted.split('.')[1].length > 2) {
        while (formatted.endsWith('0')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
        if (formatted.endsWith('.')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
      }
    } else {
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
    }
    
    return (isNegative ? "-" : "") + formatted + suffixes[suffixIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration( 
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResourceItem(
            emoji: '💰',
            value: _formattedGold,
            gain: _formattedGoldGain,
            width: 80,
          ),
          _ResourceItem(
            emoji: '👥',
            value: _formattedPopulation,
            gain: _formattedPopulationGain,
            width: 80,
          ),
          _ResourceItem(
            emoji: '🏭',
            value: _formattedIndustry,
            width: 80,
            showPlaceholder: true,
          ),
          _ResourceItem(
            emoji: '⚔️',
            value: _formattedArmyReserve,
            gain: _formattedArmyGain,
            width: 80,
          ),
        ],
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String? gain;
  final double width;
  final bool showPlaceholder;

  const _ResourceItem({
    required this.emoji,
    required this.value,
    this.gain,
    required this.width,
    this.showPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 13,
            child: gain != null ? Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '+$gain',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ) : (showPlaceholder ? const SizedBox(height: 11) : null),
          ),
        ],
      ),
    );
  }
} 