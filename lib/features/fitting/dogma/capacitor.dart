import 'dart:math' as math;

/// Capacitor model.
///
/// EVE's recharge curve: dC/dt = (10 * Cmax / tau) * (sqrt(C/Cmax) - C/Cmax), tau = rechargeRate
/// in seconds. It peaks at 25 % charge with 2.5 * Cmax / tau. With a constant average drain D the
/// capacitor settles where recharge equals drain: with k = D * tau / (10 * Cmax) and
/// s = (1 + sqrt(1 - 4k)) / 2, the stable level is s^2. If D is above the peak there is no
/// equilibrium and the time to run dry is found by integrating the same equation.
class CapacitorResult {
  const CapacitorResult({
    required this.capacity,
    required this.rechargeSeconds,
    required this.drainPerSecond,
    required this.stableFraction,
    required this.secondsToEmpty,
  });

  final double capacity;
  final double rechargeSeconds;

  /// Average GJ/s used by active modules minus what boosters inject.
  final double drainPerSecond;

  /// 0..1 when stable, null when the capacitor runs out.
  final double? stableFraction;

  /// Null when stable.
  final double? secondsToEmpty;

  double get peakRecharge => rechargeSeconds <= 0 ? 0 : 2.5 * capacity / rechargeSeconds;

  bool get stable => stableFraction != null;
}

CapacitorResult simulateCapacitor({
  required double capacity,
  required double rechargeSeconds,
  required double drainPerSecond,
}) {
  if (capacity <= 0 || rechargeSeconds <= 0) {
    return CapacitorResult(
      capacity: capacity,
      rechargeSeconds: rechargeSeconds,
      drainPerSecond: drainPerSecond,
      stableFraction: drainPerSecond <= 0 ? 1 : null,
      secondsToEmpty: drainPerSecond <= 0 ? null : 0,
    );
  }
  if (drainPerSecond <= 0) {
    return CapacitorResult(
      capacity: capacity,
      rechargeSeconds: rechargeSeconds,
      drainPerSecond: drainPerSecond,
      stableFraction: 1,
      secondsToEmpty: null,
    );
  }
  final k = drainPerSecond * rechargeSeconds / (10 * capacity);
  if (k <= 0.25) {
    final s = (1 + math.sqrt(1 - 4 * k)) / 2;
    return CapacitorResult(
      capacity: capacity,
      rechargeSeconds: rechargeSeconds,
      drainPerSecond: drainPerSecond,
      stableFraction: s * s,
      secondsToEmpty: null,
    );
  }
  return CapacitorResult(
    capacity: capacity,
    rechargeSeconds: rechargeSeconds,
    drainPerSecond: drainPerSecond,
    stableFraction: null,
    secondsToEmpty: timeToEmpty(capacity: capacity, rechargeSeconds: rechargeSeconds, drainPerSecond: drainPerSecond),
  );
}

/// RK4 on the recharge equation, starting full, until the charge reaches zero.
double timeToEmpty({required double capacity, required double rechargeSeconds, required double drainPerSecond}) {
  double rate(double c) {
    final f = (c / capacity).clamp(0.0, 1.0);
    return 10 * capacity / rechargeSeconds * (math.sqrt(f) - f) - drainPerSecond;
  }

  const dt = 0.05;
  var c = capacity;
  var t = 0.0;
  while (c > 0 && t < 24 * 3600) {
    final k1 = rate(c);
    final k2 = rate(c + dt / 2 * k1);
    final k3 = rate(c + dt / 2 * k2);
    final k4 = rate(c + dt * k3);
    final next = c + dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4);
    if (next <= 0) {
      // linear interpolation inside the last step
      return t + dt * c / (c - next);
    }
    c = next;
    t += dt;
  }
  return t;
}
