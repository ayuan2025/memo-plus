import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/voice/quick_spectrum_animator.dart';

void main() {
  test('rises quickly toward target bars', () {
    final animator = QuickSpectrumAnimator(barCount: 4);
    animator.setTargetBars(const <double>[1.0, 0.8, 0.5, 0.2]);

    animator.tick(1 / 60);

    expect(animator.displayBars.first, greaterThan(0.25));
    expect(animator.displayBars[1], greaterThan(0.2));
  });

  test('falls slowly with gravity after target drops', () {
    final animator = QuickSpectrumAnimator(barCount: 1);
    animator.setTargetBars(const <double>[1.0]);
    animator.tick(1 / 60);
    final raised = animator.displayBars.single;

    animator.setTargetBars(const <double>[0.0]);
    animator.tick(1 / 60);

    expect(animator.displayBars.single, lessThan(raised));
    expect(animator.displayBars.single, greaterThan(0.0));
  });

  test('hard reset clears bars immediately', () {
    final animator = QuickSpectrumAnimator(barCount: 2);
    animator.setTargetBars(const <double>[1.0, 0.5]);
    animator.tick(1 / 60);

    animator.reset(hard: true);

    expect(animator.displayBars, everyElement(0.0));
    expect(animator.targetBars, everyElement(0.0));
  });
}
