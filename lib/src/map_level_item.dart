import 'dart:math';

import 'package:ziggurat/ziggurat.dart';

import 'map_level.dart';

/// A single thing in the [MapLevel] instance.
class MapLevelItem {
  /// Create an instance.
  const MapLevelItem({
    required this.name,
    required this.earcon,
    required this.descriptionText,
    required this.descriptionSound,
    this.coordinates,
    this.ambiance,
    this.ambianceGain = 0.5,
  });

  /// The name of this item.
  ///
  /// THis value is used only for reference.
  final String name;

  /// The coordinates of this object.
  final Point<int>? coordinates;

  /// The ambiance for this item.
  final AssetReference? ambiance;

  /// The gain for the [ambiance].
  final double ambianceGain;

  /// The earcon heard when tabbing to this item.
  final AssetReference earcon;

  /// The textual description.
  final String descriptionText;

  /// The description of this item.
  final AssetReference descriptionSound;
}