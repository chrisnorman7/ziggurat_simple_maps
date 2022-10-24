import 'dart:math';

import 'package:dart_sdl/dart_sdl.dart';
import 'package:test/test.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_simple_maps/ziggurat_simple_maps.dart';

void main() {
  final sdl = Sdl();
  final game =
      Game(title: 'Test Game', sdl: sdl, soundBackend: SilentSoundBackend());
  const earcon1 = AssetReference.file('earcon1.mp3');
  const earcon2 = AssetReference.collection('earcon2');
  group(
    'MapLevel class',
    () {
      const grass = MapLevelTerrain(start: Point(0, 0), end: Point(10, 1));
      const water = MapLevelTerrain(start: Point(0, 2), end: Point(10, 4));
      test(
        'Initialisation',
        () {
          final level = MapLevel(game: game, terrains: [grass, water]);
          expect(level.coordinates, const Point(0, 0));
          expect(level.currentItemPosition, null);
          expect(level.currentTerrain, null);
          expect(level.defaultFootstepSound, null);
          expect(level.heading, 0.0);
          expect(level.interfaceSoundsChannel, isA<SoundChannel>());
          expect(level.items, isEmpty);
          expect(level.lastEarcon, null);
          expect(level.lastMoved, 0);
          expect(level.lastTurn, 0);
          expect(level.maxX, 100);
          expect(level.maxY, 100);
          expect(level.moving, null);
          expect(level.reverb, null);
          expect(level.reverbPreset, null);
          expect(level.sonarBeaconSound, null);
          expect(level.sonarDistanceMultiplier, 75);
          expect(level.sonarHereSound, null);
          expect(level.terrains, [grass, water]);
          expect(level.tiles, isEmpty);
          expect(level.turning, null);
          expect(level.wallSound, null);
          expect(level.watching, null);
        },
      );

      test(
        '.sortedItems',
        () {
          const item1 = MapLevelItem(
            name: 'Item 1',
            earcon: earcon1,
            descriptionText: 'The first item.',
            descriptionSound: earcon2,
            coordinates: Point(3, 3),
          );
          const item2 = MapLevelItem(
            name: 'Item 2',
            earcon: earcon2,
            descriptionText: 'The second item.',
            descriptionSound: earcon1,
            coordinates: Point(1, 1),
          );
          final level = MapLevel(
            game: game,
            items: [
              item1,
              item2,
            ],
          );
          expect(level.sortedItems, [item2, item1]);
          const item3 = MapLevelItem(
            name: 'Item 3',
            earcon: earcon1,
            descriptionText: 'The third item.',
            descriptionSound: earcon2,
            coordinates: Point(10, 0),
          );
          level.items.add(item3);
          expect(level.sortedItems, [item2, item1, item3]);
          const item4 = MapLevelItem(
            name: 'Item 4',
            earcon: earcon2,
            descriptionText: 'The fourth item.',
            descriptionSound: earcon1,
          );
          level.items.add(item4);
          expect(level.sortedItems, [item4, item2, item1, item3]);
        },
      );

      test(
        '.getTerrain',
        () {
          final level = MapLevel(game: game, terrains: [grass, water])
            ..onPush();
          for (final terrain in [grass, water]) {
            for (var x = terrain.start.x; x <= terrain.end.x; x++) {
              for (var y = terrain.start.y; y <= terrain.end.y; y++) {
                expect(level.getTerrain(Point(x, y)), terrain);
              }
            }
          }
        },
      );

      test(
        '.turnPlayer',
        () {
          final level = MapLevel(game: game);
          expect(level.heading, 0.0);
          level.turnPlayer(TurnDirections.right);
          expect(level.heading, level.turnAmount);
          expect(
            game.soundBackend.listenerOrientation,
            predicate<ListenerOrientation>((final value) {
              final orientation = ListenerOrientation.fromAngle(level.heading);
              return value.x1 == orientation.x1 &&
                  value.x2 == orientation.x2 &&
                  value.y1 == orientation.y1 &&
                  value.y2 == orientation.y2 &&
                  value.z1 == orientation.z1 &&
                  value.z2 == orientation.z2;
            }),
          );
          level.turnPlayer(TurnDirections.left);
          expect(level.heading, 0);
          expect(
            game.soundBackend.listenerOrientation,
            predicate<ListenerOrientation>((final value) {
              final orientation = ListenerOrientation.fromAngle(level.heading);
              return value.x1 == orientation.x1 &&
                  value.x2 == orientation.x2 &&
                  value.y1 == orientation.y1 &&
                  value.y2 == orientation.y2 &&
                  value.z1 == orientation.z1 &&
                  value.z2 == orientation.z2;
            }),
          );
          level.turnPlayer(TurnDirections.left);
          expect(level.heading, 360 - level.turnAmount);
          expect(
            game.soundBackend.listenerOrientation,
            predicate<ListenerOrientation>((final value) {
              final orientation = ListenerOrientation.fromAngle(level.heading);
              return value.x1 == orientation.x1 &&
                  value.x2 == orientation.x2 &&
                  value.y1 == orientation.y1 &&
                  value.y2 == orientation.y2 &&
                  value.z1 == orientation.z1 &&
                  value.z2 == orientation.z2;
            }),
          );
          level.turnPlayer(TurnDirections.right);
          expect(level.heading, 0);
          expect(
            game.soundBackend.listenerOrientation,
            predicate<ListenerOrientation>((final value) {
              final orientation = ListenerOrientation.fromAngle(level.heading);
              return value.x1 == orientation.x1 &&
                  value.x2 == orientation.x2 &&
                  value.y1 == orientation.y1 &&
                  value.y2 == orientation.y2 &&
                  value.z1 == orientation.z1 &&
                  value.z2 == orientation.z2;
            }),
          );
        },
      );

      test(
        '.movePlayer',
        () {
          final level = MapLevel(game: game)..onPush();
          expect(level.coordinates, const Point(0.0, 0.0));
        },
      );
    },
  );
}
