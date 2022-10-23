import 'map_level_item.dart';

/// Context about watching an item.
class WatchItem {
  /// Create an instance.
  WatchItem({
    required this.item,
    this.beaconLastPlayed = 0,
  });

  /// The item to watch.
  final MapLevelItem item;

  /// The last time the beacon was heard.
  int beaconLastPlayed;
}
