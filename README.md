https://youtube.com/shorts/nAOBHJdSWW0?si=7FuiB8lojU4RU6aD

# sweccathon
A mobile-first strategy simulation game where players guide a nation through real-time historical development. Built with Flutter, the game features a province-based SVG map, daily tick progression, discrete unit movement, and military front management. Designed to be cross-platform and offline-first for now. 


# Flutter Strategy Game Development Guide (Mobile, Offline-First)

This documentation outlines how to build a mobile strategy simulation game using Flutter. The game is designed with a time-based progression system (e.g., January 1st to January 2nd), a province-based map (SVG), and discrete unit movements and battles. It's designed to run offline-first with the option to expand into online sync later.

---

## 1. Project Overview

**Game Type**: 2D Strategy Simulation  
**Core Mechanics**:
- Day-by-day progression (tick-based time system)
- Province-based unit control
- Discrete unit movements (1 province at a time)
- Battle simulation when multiple armies enter the same province

**Technologies**:
- Flutter (Dart)
- `flutter_svg` for SVG map rendering
- `provider` or `riverpod` for state management
- `hive` or `isar` for offline persistence

---

## 2. File/Folder Structure
```
lib/
  main.dart
  app.dart
  core/
    game_loop.dart
    tick_engine.dart
    game_clock.dart
  models/
    army.dart
    battle.dart
    province.dart
    game_state.dart
  services/
    battle_service.dart
    movement_service.dart
    storage_service.dart
  ui/
    home_screen.dart
    map_view.dart
    province_icon.dart
    game_ui.dart
assets/
  maps/
    map.svg
  icons/
    army.png
    battle.png
```

---

## 3. Game Loop (Time Simulation)

### `game_loop.dart`
```dart
class GameLoop {
  Timer? _timer;
  Duration tickDuration;
  final VoidCallback onTick;

  GameLoop({required this.tickDuration, required this.onTick});

  void start() {
    _timer = Timer.periodic(tickDuration, (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
  }

  void changeSpeed(Duration newDuration) {
    stop();
    tickDuration = newDuration;
    start();
  }
}
```

---

## 4. Province System

### `province.dart`
```dart
class Province {
  final String id;
  final String name;
  final List<String> neighbors;
  String? occupyingArmyId;
  String? ongoingBattleId;

  Province({required this.id, required this.name, required this.neighbors});
}
```

### Map Interactivity
- Use `flutter_svg` to load SVG.
- Assign IDs to `<path>` tags in the SVG file.
- Use `GestureDetector` or custom overlay logic for province click detection.

---

## 5. Unit Movement

### `army.dart`
```dart
class Army {
  final String id;
  String currentProvince;
  String? destinationProvince;
  int daysToArrive;

  void tick() {
    if (destinationProvince != null) {
      daysToArrive--;
      if (daysToArrive <= 0) {
        currentProvince = destinationProvince!;
        destinationProvince = null;
      }
    }
  }
}
```

### `movement_service.dart`
Handles validation and assignment of movement.

---

## 6. Battle System

### `battle.dart`
```dart
class Battle {
  final String id;
  final String provinceId;
  List<String> armyIds;
  int duration;

  void tick() {
    // apply battle logic each day
  }
}
```

### `battle_service.dart`
Handles engagement creation and damage calculations.

---

## 7. UI Layer

### `map_view.dart`
```dart
class MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset('assets/maps/map.svg'),
        // Add province overlays if needed
      ],
    );
  }
}
```

### `game_ui.dart`
- Includes game speed controls (e.g., x1, x3, x5)
- Shows current date, army info, province stats

---

## 8. Game State Management

Use Riverpod or Provider to manage global game state:
- Current date
- List of provinces, armies, battles
- Game speed / paused state

---

## 9. Offline Data Persistence

### With `hive`:
- Store `gameState` on every tick or movement
- Load on app restart

```dart
final box = await Hive.openBox('game_state');
await box.put('state', gameState.toJson());
```

---

## 10. Next Steps and Considerations

### Expansion
- Add save/load functionality
- Add user profiles and achievements
- Add simple animations using `AnimatedPositioned`

### Challenges to Watch For
- Performance when redrawing the map
- SVG touch detection (requires precision layout)
- Game balance (scaling economy, war, population growth)

---

## Resources
- [flutter_svg package](https://pub.dev/packages/flutter_svg)
- [Flame Engine (optional)](https://flame-engine.org/)
- [Riverpod for state management](https://riverpod.dev/)
- [Hive local storage](https://docs.hivedb.dev/#/)

---

Let me know if you want this turned into a GitHub README or project boilerplate.

