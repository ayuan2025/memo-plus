import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/voice/quick_spectrum_frame.dart';

void main() {
  test('parses valid payload', () {
    final frame = QuickSpectrumFrame.tryParse(<String, Object?>{
      'bars': List<double>.filled(QuickSpectrumFrame.barCount, 0.5),
      'rmsLevel': 0.4,
      'peakLevel': 0.7,
      'hasVoice': true,
      'sequence': 3,
    });

    expect(frame, isNotNull);
    expect(frame!.bars, hasLength(QuickSpectrumFrame.barCount));
    expect(frame.rmsLevel, 0.4);
    expect(frame.peakLevel, 0.7);
    expect(frame.hasVoice, isTrue);
    expect(frame.sequence, 3);
  });

  test('rejects invalid payload', () {
    expect(QuickSpectrumFrame.tryParse(null), isNull);
    expect(
      QuickSpectrumFrame.tryParse(<String, Object?>{
        'bars': const <double>[0.1, 0.2],
        'rmsLevel': 0.3,
        'peakLevel': 0.5,
        'hasVoice': true,
        'sequence': 1,
      }),
      isNull,
    );
  });
}
