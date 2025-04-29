// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'style/my_transition.dart';
import 'style/palette.dart';
import 'ui/home_screen.dart';
import 'ui/game_saves_screen.dart';
import 'ui/save_game_screen.dart';
// import 'ui/map_view.dart';
import 'ui/scenarios_screen.dart';
import 'ui/country_list_1914_screen.dart';
import 'ui/game_view_screen.dart';
import 'data/world_1914.dart';
import 'models/game_types.dart';

/// The router describes the game's navigational hierarchy
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: '/',
      builder: (context, state) => const HomeScreen(key: Key('home')),
      routes: [
        GoRoute(
          path: 'save-games',
          builder: (context, state) => const SaveGameScreen(key: Key('save games')),
        ),
        GoRoute(
          path: 'game-saves',
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey('game-saves'),
            color: context.watch<Palette>().backgroundLevelSelection,
            child: const GameSavesScreen(
              key: Key('game saves'),
            ),
          ),
        ),
        // GoRoute(
        //   path: 'map-view',
        //   pageBuilder: (context, state) => buildMyTransition<void>(
        //     key: const ValueKey('map-view'),
        //     color: context.watch<Palette>().backgroundPlaySession,
        //     child: MapView(
        //       key: const Key('map view'),
        //       saveData: state.uri.queryParameters['saveData'],
        //     ),
        //   ),
        // ),
        GoRoute(
          path: 'scenarios',
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey('scenarios'),
            color: context.watch<Palette>().backgroundLevelSelection,
            child: const ScenariosScreen(
              key: Key('scenarios'),
            ),
          ),
        ),
        GoRoute(
          path: 'country-list-1914',
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey('country-list-1914'),
            color: context.watch<Palette>().backgroundPlaySession,
            child: const CountryList1914Screen(
              key: Key('country list 1914'),
            ),
          ),
        ),
        GoRoute(
          path: 'game-view/:nationTag',
          pageBuilder: (context, state) {
            final nationTag = state.pathParameters['nationTag'] ?? 'FRA';
            final saveSlot = (state.extra as Map<String, dynamic>?)?['saveSlot'] as int?;
            
            // If this is a new game (no save slot), redirect to save game screen
            if (saveSlot == null) {
              final nation = world1914.nations.firstWhere(
                (n) => n.nationTag == nationTag,
                orElse: () => world1914.playerNation,
              );
              
              // Create a new game with the selected nation as the player nation
              final game = Game(
                id: 'game_${DateTime.now().millisecondsSinceEpoch}',
                gameName: 'New Game',
                date: 0,  // Start at day 0 (1914-01-01)
                mapName: 'world_provinces',
                playerNationTag: nationTag,
                nations: [nation, ...world1914.nations.where((n) => n.nationTag != nationTag)],
                provinces: world1914.provinces,
              );

              return buildMyTransition<void>(
                key: ValueKey('save-game'),
                color: context.watch<Palette>().backgroundLevelSelection,
                child: SaveGameScreen(
                  key: Key('save game'),
                  newGame: game,
                ),
              );
            }

            // Load existing game
            final nation = world1914.nations.firstWhere(
              (n) => n.nationTag == nationTag,
              orElse: () => world1914.playerNation,
            );
            
            return buildMyTransition<void>(
              key: ValueKey('game-view-$nationTag'),
              color: context.watch<Palette>().backgroundPlaySession,
              child: GameViewScreen(
                key: Key('game view $nationTag'),
                game: world1914,
                saveSlot: saveSlot,
                nationTag: nationTag,
              ),
            );
          },
        ),
      ],
    ),
  ],
);
