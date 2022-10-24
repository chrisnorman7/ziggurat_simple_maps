import 'dart:math';

import 'package:dart_sdl/dart_sdl.dart';
import 'package:ziggurat/levels.dart';
import 'package:ziggurat/sound.dart';
import 'package:ziggurat/ziggurat.dart';

import 'map_level_item.dart';
import 'map_level_terrain.dart';
import 'watch_item.dart';

/// A level which represents a map.
class MapLevel extends Level {
  /// Create an instance.
  MapLevel({
    required super.game,
    this.maxX = 100,
    this.maxY = 100,
    this.terrains = const [],
    this.coordinates = const Point(0.0, 0.0),
    this.heading = 0,
    this.turnInterval = 20,
    this.turnAmount = 5,
    this.moveInterval = 500,
    this.moveDistance = 1.0,
    this.defaultFootstepSound,
    this.wallSound,
    this.sonarDistanceMultiplier = 75,
    this.items = const [],
    this.reverbPreset,
    final List<Ambiance> levelAmbiances = const [],
    super.music,
    super.randomSounds,
    this.moving,
    this.turning,
    this.lastMoved = 0,
    this.lastTurn = 0,
    this.currentTerrain,
    this.moveAxis = GameControllerAxis.lefty,
    this.moveThreshold = 0.2,
    this.turnAxis = GameControllerAxis.rightx,
    this.turnThreshold = 0.2,
    this.sonarBeaconSound,
    this.sonarHereSound,
    this.forwardsCommandTriggerName = 'move_forwards',
    this.backwardsCommandTriggerName = 'move_backwards',
    this.turnLeftCommandTriggerName = 'turn_left',
    this.turnRightCommandTriggerName = 'turn_right',
    this.activateTerrainCommandTriggerName = 'activate_terrain',
    this.describeItemCommandTriggerName = 'describe_item',
    this.previousItemCommandTriggerName = 'previous_item',
    this.nextItemCommandTriggerName = 'next_item',
    this.lastEarcon,
    this.currentItemPosition,
    this.watchItemCommandTriggerName = 'watch_item',
  })  : tiles = [],
        interfaceSoundsChannel = game.createSoundChannel(),
        super(
          ambiances: [
            ...levelAmbiances,
            ...items
                .where((final element) => element.ambiance != null)
                .map<Ambiance>(
                  (final item) => Ambiance(
                    sound: item.ambiance!,
                    gain: item.ambianceGain,
                    position: item.coordinates?.toDouble(),
                  ),
                )
          ],
        );

  /// The name of the command trigger to watch an item.
  String watchItemCommandTriggerName;

  /// The name of the command trigger to describe the current item.
  String describeItemCommandTriggerName;

  /// The name of the command trigger to inspect the previous item.
  String previousItemCommandTriggerName;

  /// The name of the command trigger to inspect the previous item.
  String nextItemCommandTriggerName;

  /// The name of the command trigger to activate the current terrain.
  String activateTerrainCommandTriggerName;

  /// The name of the command trigger to turn left.
  String turnLeftCommandTriggerName;

  /// The name of the command trigger to turn right.
  String turnRightCommandTriggerName;

  /// The name of the command trigger to move the player backwards.
  final String backwardsCommandTriggerName;

  /// The name of the command trigger to move the player forwards.
  final String forwardsCommandTriggerName;

  /// The max x + 1 of this map.
  final int maxX;

  /// The max y + 1 of this map.
  final int maxY;

  /// The features of this map.
  final List<MapLevelTerrain> terrains;

  /// The loaded tiles.
  final List<List<MapLevelTerrain?>> tiles;

  /// The heading of the player.
  double heading;

  /// How many millisecond must elapse between turns.
  final int turnInterval;

  /// How many degrees will be turned each turn.
  final int turnAmount;

  /// How often the player can move.
  final int moveInterval;

  /// How far the player will move each time they move.
  final double moveDistance;

  /// The coordinates of the player.
  Point<double> coordinates;

  /// The default footstep sound to use.
  final AssetReference? defaultFootstepSound;

  /// The wall sound to use.
  final AssetReference? wallSound;

  /// The multiplier for sonar distances.
  final int sonarDistanceMultiplier;

  /// The items on this map.
  final List<MapLevelItem> items;

  /// The sorted version of the [items] list.
  ///
  /// This list will be sorted by the distance from [coordinates].
  List<MapLevelItem> get sortedItems => List<MapLevelItem>.from(items)
    ..sort(
      (final a, final b) {
        final c = coordinates.floor();
        final aCoordinates = a.coordinates;
        final bCoordinates = b.coordinates;
        if (aCoordinates == null || bCoordinates == null) {
          return 0;
        }
        return c.distanceTo(aCoordinates).compareTo(c.distanceTo(bCoordinates));
      },
    );

  /// Information about the item being watched.
  WatchItem? watching;

  /// The last earcon sound to play.
  Sound? lastEarcon;

  /// The reverb preset to play sounds through.
  final ReverbPreset? reverbPreset;

  /// The interface sounds channel to use.
  ///
  /// This channel will be affected by [reverbPreset], if [reverbPreset] is not
  /// `null`.
  final SoundChannel interfaceSoundsChannel;

  /// The reverb send to be used by [interfaceSoundsChannel].
  late final BackendReverb? reverb;

  /// The stick to move the character.
  final GameControllerAxis moveAxis;

  /// The threshold for moving.
  final double moveThreshold;

  /// The stick used for turning.
  final GameControllerAxis turnAxis;

  /// The turning threshold.
  final double turnThreshold;

  /// The sound to play to indicate the distance of a [WatchItem] instance.
  final AssetReference? sonarBeaconSound;

  /// The sound to play when a [WatchItem] instance is here.
  final AssetReference? sonarHereSound;

  /// Whether or not the player is moving.
  ///
  /// If this value is `null`, the player is considered stationary.
  MovementDirections? moving;

  /// Whether or not the player is turning.
  TurnDirections? turning;

  /// The time the last move was performed.
  int lastMoved;

  /// The time the last turn was performed.
  int lastTurn;

  /// The current position in the items menu.
  int? currentItemPosition;

  /// The current terrain.
  MapLevelTerrain? currentTerrain;

  /// Get the feature at the given [position].
  MapLevelTerrain? getTerrain(final Point<int> position) =>
      tiles[position.x][position.y];

  /// Handle sdl events.
  @override
  void handleSdlEvent(final Event event) {
    if (event is ControllerAxisEvent) {
      final value = event.smallValue;
      if (event.axis == moveAxis) {
        if (value.abs() > moveThreshold) {
          moving = value > 0
              ? MovementDirections.backward
              : MovementDirections.forward;
        } else {
          moving = null;
        }
      } else if (event.axis == turnAxis) {
        if (value.abs() >= turnThreshold) {
          turning = value < 0 ? TurnDirections.left : TurnDirections.right;
        } else {
          turning = null;
        }
      } else {
        super.handleSdlEvent(event);
      }
    } else {
      super.handleSdlEvent(event);
    }
  }

  /// Turn the player in the given [direction].
  void turnPlayer(final TurnDirections direction) {
    if (direction == TurnDirections.left) {
      heading = (heading - turnAmount) % 360;
    } else {
      heading = (heading + turnAmount) % 360;
    }
    game.setListenerOrientation(heading);
  }

  /// Move the player in the given [direction].
  void movePlayer(final MovementDirections direction) {
    final Point<double> newCoordinates;
    if (direction == MovementDirections.forward) {
      newCoordinates = coordinatesInDirection(
        coordinates,
        heading,
        moveDistance,
      );
    } else {
      newCoordinates = coordinatesInDirection(
        coordinates,
        heading,
        moveDistance * -1,
      );
    }
    if (newCoordinates.x < 0 ||
        newCoordinates.y < 0 ||
        newCoordinates.x >= maxX ||
        newCoordinates.y >= maxY) {
      final sound = wallSound;
      if (sound != null) {
        playSound(sound: sound);
      }
    } else {
      coordinates = newCoordinates;
      game.setListenerPosition(coordinates.x, coordinates.y, 0.0);
      final oldTerrain = currentTerrain;
      final newTerrain = getTerrain(newCoordinates.floor());
      final footstepSound = newTerrain?.footstepSound ?? defaultFootstepSound;
      if (footstepSound != null) {
        playSound(sound: footstepSound);
      }
      if (newTerrain != oldTerrain) {
        oldTerrain?.onExit?.call();
        newTerrain?.onEnter?.call();
        currentTerrain = newTerrain;
      }
    }
  }

  /// Update the given [watch].
  void updateWatch({
    required final WatchItem watch,
    required final int timeDelta,
  }) {
    final d = coordinates.distanceTo(watch.item.coordinates!.toDouble());
    if (d < 1) {
      if (watch.beaconLastPlayed != 0) {
        watching = null;
        final sound = sonarHereSound;
        if (sound != null) {
          game.playSimpleSound(sound: sound);
        }
      }
    } else {
      final time = (d * sonarDistanceMultiplier).floor();
      watch.beaconLastPlayed += timeDelta;
      if (watch.beaconLastPlayed >= time) {
        watch.beaconLastPlayed = 0;
        final sound = sonarBeaconSound;
        if (sound != null) {
          game.playSimpleSound(sound: sound);
        }
      }
    }
  }

  /// Handle movement.
  @override
  void tick(final int timeDelta) {
    super.tick(timeDelta);
    lastMoved += timeDelta;
    lastTurn += timeDelta;
    final turnDirection = turning;
    if (turnDirection != null && lastTurn >= turnInterval) {
      lastTurn = 0;
      turnPlayer(turnDirection);
    }
    final moveDirection = moving;
    if (moveDirection != null && lastMoved >= moveInterval) {
      lastMoved = 0;
      movePlayer(moveDirection);
    }
    final w = watching;
    if (w != null) {
      updateWatch(watch: w, timeDelta: timeDelta);
    }
  }

  /// Play the given [sound] at the given [gain].
  Sound playSound({
    required final AssetReference sound,
    final double gain = 0.7,
    final bool keepAlive = false,
  }) =>
      interfaceSoundsChannel.playSound(
        assetReference: sound,
        gain: gain,
        keepAlive: keepAlive,
      );

  /// Set the listener.
  @override
  void onPush({final double? fadeLength}) {
    game
      ..setListenerOrientation(heading)
      ..setListenerPosition(coordinates.x, coordinates.y, 0.0);
    tiles.clear();
    while (tiles.length < maxX) {
      tiles.add(List.generate(maxY, (final index) => null));
    }
    terrains.forEach(registerTerrain);
    final preset = reverbPreset;
    if (preset != null) {
      final r = game.createReverb(preset);
      interfaceSoundsChannel.addReverb(reverb: r);
      game.ambianceSounds.addReverb(reverb: r);
      reverb = r;
    } else {
      reverb = null;
    }
    registerCommand(
      forwardsCommandTriggerName,
      Command(
        onStart: () => moving = MovementDirections.forward,
        onStop: () => moving = null,
      ),
    );
    registerCommand(
      backwardsCommandTriggerName,
      Command(
        onStart: () => moving = MovementDirections.backward,
        onStop: () => moving = null,
      ),
    );
    registerCommand(
      turnLeftCommandTriggerName,
      Command(
        onStart: () => turning = TurnDirections.left,
        onStop: () => turning = null,
      ),
    );
    registerCommand(
      turnRightCommandTriggerName,
      Command(
        onStart: () => turning = TurnDirections.right,
        onStop: () => turning = null,
      ),
    );
    registerCommand(
      activateTerrainCommandTriggerName,
      Command(
        onStart: () => getTerrain(coordinates.floor())?.onActivate?.call(),
      ),
    );
    registerCommand(nextItemCommandTriggerName, Command(onStart: nextItem));
    registerCommand(
      previousItemCommandTriggerName,
      Command(onStart: previousItem),
    );
    registerCommand(
      describeItemCommandTriggerName,
      Command(onStart: describeItem),
    );
    registerCommand(watchItemCommandTriggerName, Command(onStart: watchItem));
    super.onPush(fadeLength: fadeLength);
  }

  /// Destroy [reverb] and [interfaceSoundsChannel].
  @override
  void onPop(final double? fadeLength) {
    reverb?.destroy();
    interfaceSoundsChannel.destroy();
    super.onPop(fadeLength);
  }

  /// Show the given [item].
  void showItem(final MapLevelItem item) {
    stopEarcon();
    lastEarcon = game.outputMessage(
      Message(
        keepAlive: true,
        sound: item.earcon,
        text: item.name,
      ),
    );
  }

  /// Stop the [lastEarcon] sound from playing.
  void stopEarcon() {
    lastEarcon?.destroy();
    lastEarcon = null;
  }

  /// Describe the current item.
  void describeItem() {
    final i = sortedItems;
    if (i.isNotEmpty) {
      final item = i[currentItemPosition ?? 0];
      stopEarcon();
      lastEarcon = game.outputMessage(
        Message(
          keepAlive: true,
          sound: item.descriptionSound,
          text: item.descriptionText,
        ),
      );
    }
  }

  /// Start or stop watching the current item.
  void watchItem() {
    if (watching != null) {
      watching = null;
    } else {
      final i = sortedItems;
      if (i.isNotEmpty) {
        final item = i[currentItemPosition ?? 0];
        final position = item.coordinates;
        if (position == null) {
          return;
        }
        watching = WatchItem(item: item);
        final sound = sonarBeaconSound;
        if (sound != null) {
          final playback = game.playSimpleSound(
            sound: sound,
            position: SoundPosition3d(
              x: position.x.toDouble(),
              y: position.y.toDouble(),
            ),
          );
          final r = reverb;
          if (r != null) {
            playback.channel.addReverb(reverb: r);
          }
          game.callAfter(
            func: playback.channel.destroy,
            runAfter: 1000,
          );
        }
      }
    }
  }

  /// Move to the next item.
  void nextItem() {
    final i = sortedItems;
    var p = currentItemPosition;
    if (p == (i.length - 1)) {
      p = 0;
    } else if (p == null) {
      p = min(1, i.length - 1);
    } else {
      p++;
    }
    currentItemPosition = p;
    showItem(i[p]);
  }

  /// Show the previous item.
  void previousItem() {
    final i = sortedItems;
    var p = currentItemPosition;
    if (p == null || p == 0) {
      p = i.length - 1;
    } else {
      p--;
    }
    currentItemPosition = p;
    showItem(i[p]);
  }

  /// Register the given [terrain].
  void registerTerrain(final MapLevelTerrain terrain) {
    for (var x = terrain.start.x; x <= terrain.end.x; x++) {
      for (var y = terrain.start.y; y <= terrain.end.y; y++) {
        final f = tiles[x][y];
        if (f != null) {
          throw StateError('Feature $terrain overlaps feature $f.');
        }
        tiles[x][y] = terrain;
      }
    }
  }

  /// Navigate to a new [mapLevel].
  void navigateTo({
    required final MapLevel mapLevel,
    final AssetReference? navigateSound,
    final double? fadeInTime = 0.5,
    final double? fadeOutTime = 3.0,
  }) {
    if (navigateSound != null) {
      game.playSimpleSound(sound: navigateSound);
    }
    game.replaceLevel(
      mapLevel,
      fadeInTime: fadeInTime,
      fadeOutTime: fadeOutTime,
    );
  }
}
