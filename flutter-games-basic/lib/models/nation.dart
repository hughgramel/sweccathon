/// Represents the difficulty level of playing as a nation
enum NationDifficulty {
  easy,
  medium,
  hard
}

/// Represents a playable nation in the game with its starting resources
class Nation {
  /// The name of the nation
  final String name;
  
  /// The flag emoji representing the nation
  final String flag;
  
  /// The difficulty level of playing this nation
  final NationDifficulty difficulty;
  
  /// Starting population in millions
  final double population;
  
  /// Starting industrial capacity in millions
  final double industry;
  
  /// Starting gold reserves in millions
  final double gold;
  
  /// Starting army size in millions
  final double army;

  const Nation({
    required this.name,
    required this.flag,
    required this.difficulty,
    required this.population,
    required this.industry,
    required this.gold,
    required this.army,
  });
}

/// List of nations available in the 1836 scenario
final nations1836 = [
  const Nation(
    name: 'France',
    flag: '🇫🇷',
    difficulty: NationDifficulty.easy,
    population: 35.2,
    industry: 8.5,
    gold: 12.3,
    army: 4.7,
  ),
  const Nation(
    name: 'Prussia',
    flag: '🇩🇪',
    difficulty: NationDifficulty.medium,
    population: 15.8,
    industry: 6.2,
    gold: 5.4,
    army: 3.9,
  ),
  const Nation(
    name: 'Austria',
    flag: '🇦🇹',
    difficulty: NationDifficulty.medium,
    population: 28.5,
    industry: 5.8,
    gold: 7.2,
    army: 4.2,
  ),
]; 