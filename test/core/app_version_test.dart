import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_version.dart';

void main() {
  group('parseVersionTriplet', () {
    test('reads the first three numeric segments', () {
      expect(parseVersionTriplet('1.2.3'), [1, 2, 3]);
      expect(parseVersionTriplet('1.0.59'), [1, 0, 59]);
    });

    test('drops a build or pre-release suffix whole', () {
      expect(parseVersionTriplet('1.0.59-pro'), [1, 0, 59]);
      expect(parseVersionTriplet('1.0.59+60'), [1, 0, 59]);
      expect(parseVersionTriplet('1.0.59-pro+60'), [1, 0, 59]);
    });

    test('zero-fills missing segments', () {
      expect(parseVersionTriplet('2'), [2, 0, 0]);
      expect(parseVersionTriplet('2.1'), [2, 1, 0]);
      expect(parseVersionTriplet(''), [0, 0, 0]);
    });

    test('ignores anything past the third segment', () {
      expect(parseVersionTriplet('1.2.3.4'), [1, 2, 3]);
    });

    test('takes the digits out of a decorated segment', () {
      // A remote that ships `v1.0.60` must not read as [0, 0, 0]: that is the
      // whole reason the about page stopped parsing with int.tryParse.
      expect(parseVersionTriplet('v1.0.60'), [1, 0, 60]);
      expect(parseVersionTriplet('1.0.60rc'), [1, 0, 60]);
    });
  });

  group('compareVersionTriplets', () {
    test('orders by major, then minor, then patch', () {
      expect(compareVersionTriplets('1.0.60', '1.0.59'), greaterThan(0));
      expect(compareVersionTriplets('1.1.0', '1.0.99'), greaterThan(0));
      expect(compareVersionTriplets('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareVersionTriplets('1.0.59', '1.0.60'), lessThan(0));
    });

    test('a suffix does not make a version newer', () {
      expect(compareVersionTriplets('1.0.59-pro', '1.0.59'), 0);
      expect(compareVersionTriplets('1.0.59', '1.0.59+60'), 0);
    });

    test('a decorated remote still compares correctly', () {
      expect(compareVersionTriplets('v1.0.60', '1.0.59'), greaterThan(0));
      expect(compareVersionTriplets('v1.0.59', '1.0.59'), 0);
    });
  });

  group('isNewerVersion', () {
    test('answers the question the update checks ask', () {
      expect(isNewerVersion('1.0.62', '1.0.61'), isTrue);
      expect(isNewerVersion('1.0.61', '1.0.61'), isFalse);
      expect(isNewerVersion('1.0.60', '1.0.61'), isFalse);
    });
  });
}
