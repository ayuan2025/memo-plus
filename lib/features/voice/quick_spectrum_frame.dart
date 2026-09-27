class QuickSpectrumFrame {
  const QuickSpectrumFrame({
    required this.bars,
    required this.rmsLevel,
    required this.peakLevel,
    required this.hasVoice,
    required this.sequence,
  });

  static const int barCount = 48;

  final List<double> bars;
  final double rmsLevel;
  final double peakLevel;
  final bool hasVoice;
  final int sequence;

  static QuickSpectrumFrame? tryParse(Object? raw) {
    if (raw is! Map) return null;

    final rawBars = raw['bars'];
    if (rawBars is! List || rawBars.length != barCount) {
      return null;
    }

    final bars = <double>[];
    for (final item in rawBars) {
      if (item is! num) return null;
      bars.add(item.toDouble().clamp(0.0, 1.0));
    }

    final rmsLevel = raw['rmsLevel'];
    final peakLevel = raw['peakLevel'];
    final hasVoice = raw['hasVoice'];
    final sequence = raw['sequence'];
    if (rmsLevel is! num ||
        peakLevel is! num ||
        hasVoice is! bool ||
        sequence is! num) {
      return null;
    }

    return QuickSpectrumFrame(
      bars: List<double>.unmodifiable(bars),
      rmsLevel: rmsLevel.toDouble().clamp(0.0, 1.0),
      peakLevel: peakLevel.toDouble().clamp(0.0, 1.0),
      hasVoice: hasVoice,
      sequence: sequence.toInt(),
    );
  }
}
