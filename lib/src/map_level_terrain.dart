import 'dart:math';

import 'package:ziggurat/ziggurat.dart';

import 'map_level.dart';

/// A terrain in a [MapLevel].
class MapLevelTerrain {
  /// Create an instance.
  const MapLevelTerrain({
    required this.start,
    required this.end,
    this.footstepSound,
    this.onActivate,
    this.onEnter,
    this.onExit,
  });

  /// The start coordinates of this terrain.
  final Point<int> start;

  /// The end coordinates of this terrain.
  final Point<int> end;

  /// The function to call when this terrain is activated.
  final TaskFunction? onActivate;

  /// The function to call when entering this terrain.
  final TaskFunction? onEnter;

  /// The function to call when exiting this terrain.
  final TaskFunction? onExit;

  /// The footstep sound to use.
  ///
  /// If this value is `null`, then [MapLevel.defaultFootstepSound] will be
  /// used.
  final AssetReference? footstepSound;
}
