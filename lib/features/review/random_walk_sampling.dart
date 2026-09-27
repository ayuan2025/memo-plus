import 'dart:math' as math;

class ReservoirSampler<T> {
  ReservoirSampler(this.limit, this.random);

  final int limit;
  final math.Random random;
  final List<T> _items = <T>[];
  var _seen = 0;

  void add(T item) {
    if (limit <= 0) return;
    _seen += 1;
    if (_items.length < limit) {
      _items.add(item);
      return;
    }
    final replaceIndex = random.nextInt(_seen);
    if (replaceIndex < limit) {
      _items[replaceIndex] = item;
    }
  }

  List<T> take() {
    final result = List<T>.from(_items, growable: false);
    result.shuffle(random);
    return result;
  }
}

List<T> sampleUpTo<T>(Iterable<T> items, int maxCount, math.Random random) {
  final sampler = ReservoirSampler<T>(maxCount, random);
  for (final item in items) {
    sampler.add(item);
  }
  return sampler.take();
}
