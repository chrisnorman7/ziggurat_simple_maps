import 'dart:math';

import 'package:dart_sdl/dart_sdl.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/ziggurat.dart';
import 'package:ziggurat_simple_maps/ziggurat_simple_maps.dart';

/// Walk forwards.
const forwardsCommandTrigger = CommandTrigger(
  name: 'forwards',
  description: 'Move forward',
  keyboardKey: CommandKeyboardKey(ScanCode.w),
);

/// Move backwards.
const backwardsCommandTrigger = CommandTrigger(
  name: 'backwards',
  description: 'Move backwards',
  keyboardKey: CommandKeyboardKey(ScanCode.s),
);

/// Turn left.
const turnLeftCommandTrigger = CommandTrigger(
  name: 'left',
  description: 'Turn left',
  keyboardKey: CommandKeyboardKey(ScanCode.a),
);

/// Turn right.
const turnRightCommandTrigger = CommandTrigger(
  name: 'right',
  description: 'Turn right',
  keyboardKey: CommandKeyboardKey(ScanCode.d),
);

/// Activate the current feature.
const activateFeature = CommandTrigger(
  name: 'activate',
  description: 'Activate current feature',
  button: GameControllerButton.x,
  keyboardKey: CommandKeyboardKey(ScanCode.return_),
);

/// Move forward through items.
const nextItemCommandTrigger = CommandTrigger(
  name: 'next_item',
  description: 'Select next item',
  button: GameControllerButton.dpadRight,
  keyboardKey: CommandKeyboardKey(ScanCode.right),
);

/// Move backwards through items.
const previousItemCommandTrigger = CommandTrigger(
  name: 'previous_item',
  description: 'Select previous item',
  button: GameControllerButton.dpadLeft,
  keyboardKey: CommandKeyboardKey(ScanCode.left),
);

/// Describe the current item.
const describeItemCommandTrigger = CommandTrigger(
  name: 'describe_item',
  description: 'Describe the currently-selected item',
  button: GameControllerButton.dpadDown,
  keyboardKey: CommandKeyboardKey(ScanCode.down),
);

/// Track the currently-selected item.
const watchItemCommandTrigger = CommandTrigger(
  name: 'watch_item',
  description: 'Watch the currently-selected item',
  button: GameControllerButton.dpadUp,
  keyboardKey: CommandKeyboardKey(ScanCode.up),
);

/// A trigger for showing the current coordinates.
const showCoordinatesCommandTrigger = CommandTrigger(
  name: 'show_coordinates',
  description: 'Show the coordinates',
  button: GameControllerButton.b,
  keyboardKey: CommandKeyboardKey(ScanCode.c),
);
Future<void> main() async {
  final sdl = Sdl()..init();
  final game = Game(
    title: 'Example Game',
    sdl: sdl,
    soundBackend: SilentSoundBackend(),
    triggerMap: const TriggerMap([
      activateFeature,
      backwardsCommandTrigger,
      forwardsCommandTrigger,
      turnLeftCommandTrigger,
      turnRightCommandTrigger,
      previousItemCommandTrigger,
      nextItemCommandTrigger,
      describeItemCommandTrigger,
      watchItemCommandTrigger,
      showCoordinatesCommandTrigger,
    ]),
  );
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
        final level = MapLevel(
          game: game,
          terrains: [t1],
          activateTerrainCommandTriggerName: activateFeature.name,
          backwardsCommandTriggerName: backwardsCommandTrigger.name,
          describeItemCommandTriggerName: describeItemCommandTrigger.name,
          forwardsCommandTriggerName: forwardsCommandTrigger.name,
          nextItemCommandTriggerName: nextItemCommandTrigger.name,
          previousItemCommandTriggerName: previousItemCommandTrigger.name,
          turnLeftCommandTriggerName: turnLeftCommandTrigger.name,
          turnRightCommandTriggerName: turnRightCommandTrigger.name,
          watchItemCommandTriggerName: watchItemCommandTrigger.name,
        );
        level.registerCommand(
          showCoordinatesCommandTrigger.name,
          Command(
            onStart: () {
              final coordinates = level.coordinates;
              game.outputText(
                '${coordinates.x.floor()}, ${coordinates.y.floor()}',
              );
            },
          ),
        );
        game.pushLevel(level);
      },
    );
  } finally {
    sdl.quit();
  }
}
