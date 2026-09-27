import 'dart:math' as math;

class QuickSpectrumAnimator {
  QuickSpectrumAnimator({
    this.barCount = 48,
    this.attack = 18.0,
    this.gravity = 3.2,
    this.maxFallVelocity = 4.5,
  }) : targetBars = List<double>.filled(barCount, 0.0),
       displayBars = List<double>.filled(barCount, 0.0),
       _fallVelocities = List<double>.filled(barCount, 0.0);

  final int barCount;
  final double attack;
  final double gravity;
  final double maxFallVelocity;

  final List<double> targetBars;
  final List<double> displayBars;
  final List<double> _fallVelocities;

  void setTargetBars(List<double> bars) {
    if (bars.length != barCount) return;
    for (var index = 0; index < barCount; index++) {
      targetBars[index] = bars[index].clamp(0.0, 1.0);
    }
  }

  void reset({required bool hard}) {
    for (var index = 0; index < barCount; index++) {
      targetBars[index] = 0.0;
      _fallVelocities[index] = 0.0;
      if (hard) {
        displayBars[index] = 0.0;
      }
    }
  }

  bool tick(double deltaSeconds) {
    final clampedDelta = deltaSeconds.clamp(1 / 240, 1 / 20);
    var changed = false;
    for (var index = 0; index < barCount; index++) {
      final current = displayBars[index];
      final target = targetBars[index];
      double next = current;
      if (target >= current) {
        final factor = (clampedDelta * attack).clamp(0.0, 1.0);
        next = current + (target - current) * factor;
        _fallVelocities[index] = 0.0;
      } else {
        final velocity = (_fallVelocities[index] + gravity * clampedDelta)
            .clamp(0.0, maxFallVelocity);
        _fallVelocities[index] = velocity;
        next = math.max(target, current - velocity * clampedDelta);
      }
      if ((next - current).abs() > 0.001) {
        changed = true;
      }
      displayBars[index] = next.clamp(0.0, 1.0);
    }
    return changed;
  }

  bool get hasVisibleBars => displayBars.any((value) => value > 0.001);
}
