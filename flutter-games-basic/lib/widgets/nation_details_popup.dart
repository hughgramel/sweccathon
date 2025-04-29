import 'package:flutter/material.dart';
import '../models/game_types.dart';

class NationDetailsPopup extends StatelessWidget {
  final Nation nation;
  final Nation playerNation;
  final Game game;
  final VoidCallback onClose;
  final VoidCallback onDeclareWar;
  final VoidCallback onMakePeace;
  final VoidCallback onFormAlliance;
  final VoidCallback onBreakAlliance;

  const NationDetailsPopup({
    super.key,
    required this.nation,
    required this.playerNation,
    required this.game,
    required this.onClose,
    required this.onDeclareWar,
    required this.onMakePeace,
    required this.onFormAlliance,
    required this.onBreakAlliance,
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

  void _showWarStatistics(BuildContext context) {
    // Calculate war casualties and deaths
    int attackerCasualties = 0;
    int defenderCasualties = 0;
    
    // Find battles between player and this nation
    for (final battle in game.battles) {
      if ((battle.attackerTag == playerNation.nationTag && battle.defenderTag == nation.nationTag) ||
          (battle.attackerTag == nation.nationTag && battle.defenderTag == playerNation.nationTag)) {
        
        if (battle.attackerTag == playerNation.nationTag) {
          attackerCasualties += battle.attackerCasualties;
          defenderCasualties += battle.defenderCasualties;
        } else {
          attackerCasualties += battle.defenderCasualties;
          defenderCasualties += battle.attackerCasualties;
        }
      }
    }
    
    final attackerDeaths = (attackerCasualties * 0.3).round();
    final defenderDeaths = (defenderCasualties * 0.3).round();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('War with ${nation.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Your Nation', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Casualties: ${_formatNumber(attackerCasualties)}'),
                      Text('Deaths: ${_formatNumber(attackerDeaths)}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(nation.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Casualties: ${_formatNumber(defenderCasualties)}'),
                      Text('Deaths: ${_formatNumber(defenderDeaths)}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAtWar = playerNation.atWarWith.contains(nation.nationTag);
    final isAllied = playerNation.allies.contains(nation.nationTag);

    // Calculate total values from provinces
    final totalPopulation = nation.getTotalPopulation(game.provinces);
    final totalGold = nation.gold;  // Current gold is stored in nation
    final totalArmy = nation.getTotalArmy(game.provinces);
    final totalIndustry = nation.getTotalIndustry(game.provinces);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nation info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nation.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/flags/${nation.nationTag.toLowerCase()}.png',
                          width: 32,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 32,
                              height: 24,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.flag,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
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
                      value: _formatNumber(totalPopulation),
                    ),
                    _StatItem(
                      emoji: '💰',
                      label: 'Gold',
                      value: _formatNumber(totalGold),
                    ),
                    _StatItem(
                      emoji: '⚔️',
                      label: 'Army',
                      value: _formatNumber(totalArmy),
                    ),
                    _StatItem(
                      emoji: '🏭',
                      label: 'Industry',
                      value: _formatNumber(totalIndustry),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isAtWar && !isAllied)
                      Expanded(
                        child: _ActionButton(
                          label: 'Declare War',
                          color: const Color(0xFFE57373),
                          shadowColor: const Color(0xFFC62828),
                          onTap: onDeclareWar,
                        ),
                      ),
                    if (isAtWar) ...[
                      Expanded(
                        child: _ActionButton(
                          label: 'Make Peace',
                          color: const Color(0xFF6EC53E),
                          shadowColor: const Color(0xFF4A9E1C),
                          onTap: onMakePeace,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'View War',
                          color: const Color(0xFFE57373),
                          shadowColor: const Color(0xFFC62828),
                          onTap: () => _showWarStatistics(context),
                        ),
                      ),
                    ],
                    if (!isAtWar && !isAllied)
                      Expanded(
                        child: _ActionButton(
                          label: 'Form Alliance',
                          color: const Color(0xFF67B9E7),
                          shadowColor: const Color(0xFF4792BA),
                          onTap: onFormAlliance,
                        ),
                      ),
                    if (isAllied)
                      Expanded(
                        child: _ActionButton(
                          label: 'Break Alliance',
                          color: const Color(0xFFE57373),
                          shadowColor: const Color(0xFFC62828),
                          onTap: onBreakAlliance,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      transform: Matrix4.translationValues(0, -2, 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 