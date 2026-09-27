import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memos_flutter_app/features/image_preview/widgets/_image_preview_progressive_raster.dart';

void main() {
  testWidgets('progressive raster expands image to parent box', (tester) async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 1, height: 1)),
    );
    final provider = MemoryImage(bytes);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: ImagePreviewProgressiveRaster(
              lowResImage: provider,
              highResImage: provider,
              fit: BoxFit.contain,
              loadingBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Image).first), const Size(200, 100));
  });
}
