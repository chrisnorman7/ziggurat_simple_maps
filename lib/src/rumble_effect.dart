import 'package:ziggurat/ziggurat.dart';

/// A class for holding data about a rumble effect.
class RumbleEffect {
  /// Create an instance.
  const RumbleEffect({
    required this.duration,
    this.lowFrequency = 65535,
    this.highFrequency = 65535,
  });

  /// The duration of the effect.
  final int duration;

  /// The low frequency.
  final int lowFrequency;

  /// The high frequency.
  final int highFrequency;

  /// Perform this effect.
  void dispatch(final Game game) => game.rumble(
        duration: duration,
        lowFrequency: lowFrequency,
        highFrequency: highFrequency,
      );
}
