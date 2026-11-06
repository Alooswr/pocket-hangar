import 'dart:math' as math;

/// Training formulas (as given in the project spec and the EVE University wiki):
///   SP per minute       = primary attribute + secondary attribute / 2   (Alpha clones: half)
///   SP to reach a level = 250 * rank * 32^((level - 1) / 2), rounded up
/// Attributes include implant bonuses.

int spForLevel(int level, double rank) {
  if (level <= 0) return 0;
  final exact = 250 * rank * math.pow(32, (level - 1) / 2);
  // pow() is not exact for the integer levels (8000.000000001); round those down first.
  return (exact - 1e-6).ceil();
}

double spPerMinute({required double primary, required double secondary, bool alpha = false}) {
  final rate = primary + secondary / 2;
  return alpha ? rate / 2 : rate;
}

Duration trainingTime({required int spNeeded, required double spPerMinute}) {
  if (spNeeded <= 0 || spPerMinute <= 0) return Duration.zero;
  return Duration(milliseconds: (spNeeded / spPerMinute * 60000).round());
}

/// Rate implied by a queue entry's dates: (level_end_sp - training_start_sp) / minutes.
double? impliedRate({
  required int? trainingStartSp,
  required int? levelEndSp,
  required DateTime? start,
  required DateTime? finish,
}) {
  if (trainingStartSp == null || levelEndSp == null || start == null || finish == null) return null;
  final minutes = finish.difference(start).inMilliseconds / 60000;
  if (minutes <= 0) return null;
  return (levelEndSp - trainingStartSp) / minutes;
}

/// Alpha clones train at half speed. ESI does not say which clone state a character is in, so
/// compare the server's rate with the Omega rate we expect from the attributes.
enum CloneGuess { omega, alpha, unknown }

CloneGuess guessClone({required double? serverRate, required double omegaRate}) {
  if (serverRate == null || omegaRate <= 0) return CloneGuess.unknown;
  final ratio = serverRate / omegaRate;
  if ((ratio - 0.5).abs() < 0.03) return CloneGuess.alpha;
  if ((ratio - 1).abs() < 0.03) return CloneGuess.omega;
  return CloneGuess.unknown;
}

String romanLevel(int level) => const ['0', 'I', 'II', 'III', 'IV', 'V'][level.clamp(0, 5)];
