import 'dart:math';

import 'package:dart_sdl/dart_sdl.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_simple_maps/ziggurat_simple_maps.dart';

Future<void> main() async {
  final sdl = Sdl();
  final game =
      Game(title: 'Example Game', sdl: sdl, soundBackend: SilentSoundBackend());
  try {
    await game.run(
      onStart: () {
        final t1 = MapLevelTerrain(
          start: const Point(0, 0),
          end: const Point(10, 2),
          onActivate: () => game.outputText('You activated me.'),
          onEnter: () => game.outputText('You entered me.'),
          onExit: () => game.outputText('You exited me.'),
        );
        final level = MapLevel(game: game, terrains: [t1]);
        game.pushLevel(level);
      },
    );
  } finally {
    sdl.quit();
  }
}
