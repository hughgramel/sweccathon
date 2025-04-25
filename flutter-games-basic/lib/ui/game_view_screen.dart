import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_types.dart';

class GameViewScreen extends StatelessWidget {
  final Nation nation;

  const GameViewScreen({
    super.key,
    required this.nation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nation.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              'Overview',
              [
                'Total Population: ${nation.totalPopulation}',
                'Gold: ${nation.gold}',
                'Gold Income: ${nation.totalGoldIncome}',
                'Research Points: ${nation.researchPoints}',
                'Total Industry: ${nation.totalIndustry}',
                'Total Army: ${nation.totalArmy}',
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Resources',
              nation.resourceCounts.entries.map((e) => 
                '${e.key.name}: ${e.value} provinces'
              ).toList(),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Research',
              [
                'Current Research: ${nation.currentResearchId ?? 'None'}',
                'Progress: ${nation.currentResearchProgress}%',
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Provinces',
              nation.provinces.map((p) => 
                '${p.name}: Pop ${p.population}, Gold ${p.goldIncome}, Industry ${p.industry}'
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, List<String> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...stats.map((stat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(stat),
            )),
          ],
        ),
      ),
    );
  }
} 