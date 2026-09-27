import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/collection_reader.dart';
import 'package:memos_flutter_app/features/collections/reader_background_resolver.dart';

void main() {
  test('solid background config resolves custom color and brightness', () {
    final preferences = CollectionReaderPreferences.defaults.copyWith(
      backgroundConfig: CollectionReaderBackgroundConfig.defaults.copyWith(
        type: CollectionReaderBackgroundType.solidColor,
        solidColor: const Color(0xFF121212),
        alpha: 0.8,
      ),
    );

    final palette = resolveReaderBackgroundPalette(preferences);

    expect(palette.background, const Color(0xCC121212));
    expect(palette.brightness, Brightness.dark);
    expect(palette.foreground, const Color(0xFFF3F4F6));
  });

  test('missing image file background falls back without crashing', () {
    final preferences = CollectionReaderPreferences.defaults.copyWith(
      backgroundConfig: CollectionReaderBackgroundConfig.defaults.copyWith(
        type: CollectionReaderBackgroundType.imageFile,
        imagePath: r'Z:\not-found\reader-background.png',
      ),
    );

    final palette = resolveReaderBackgroundPalette(preferences);

    expect(palette.imageProvider, isNull);
    expect(palette.background, isNotNull);
  });
}
