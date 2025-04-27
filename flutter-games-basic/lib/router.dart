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
// import 'ui/map_view.dart';
import 'ui/scenarios_screen.dart';
import 'ui/country_list_1836_screen.dart';
import 'ui/game_view_screen.dart';
import 'data/world_1836.dart';

/// The router describes the game's navigational hierarchy
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(key: Key('home')),
      routes: [
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
          path: 'country-list-1836',
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey('country-list-1836'),
            color: context.watch<Palette>().backgroundPlaySession,
            child: const CountryList1836Screen(
              key: Key('country list 1836'),
            ),
          ),
        ),
        GoRoute(
          path: 'game-view/:nationTag',
          pageBuilder: (context, state) {
            final nationTag = state.pathParameters['nationTag'] ?? 'FRA';
            final nation = world1836.nations.firstWhere(
              (n) => n.nationTag == nationTag,
              orElse: () => world1836.playerNation,
            );
            return buildMyTransition<void>(
              key: ValueKey('game-view-$nationTag'),
              color: context.watch<Palette>().backgroundPlaySession,
              child: GameViewScreen(
                key: Key('game view $nationTag'),
                game: world1836,
              ),
            );
          },
        ),
      ],
    ),
  ],
);
