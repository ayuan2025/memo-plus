import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/models/collection_reader.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_animation_delegate.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_no_anim_delegate.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_simulation_delegate.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_slide_delegate.dart';

void main() {
  test('simulation support is limited to mobile native platforms', () {
    expect(
      isCollectionReaderSimulationSupported(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      isCollectionReaderSimulationSupported(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      isFalse,
    );
    expect(
      isCollectionReaderSimulationSupported(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
  });

  test('effective page animation falls back from simulation to slide', () {
    expect(
      resolveEffectiveCollectionReaderPageAnimation(
        CollectionReaderPageAnimation.simulation,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      CollectionReaderPageAnimation.simulation,
    );
    expect(
      resolveEffectiveCollectionReaderPageAnimation(
        CollectionReaderPageAnimation.simulation,
        isWeb: false,
        platform: TargetPlatform.macOS,
      ),
      CollectionReaderPageAnimation.slide,
    );
    expect(
      resolveEffectiveCollectionReaderPageAnimation(
        CollectionReaderPageAnimation.simulation,
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      CollectionReaderPageAnimation.slide,
    );
  });

  test('delegate resolver returns delegate for effective animation', () {
    expect(
      resolveCollectionReaderAnimationDelegate(
        CollectionReaderPageAnimation.none,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isA<NoAnimDelegate>(),
    );
    expect(
      resolveCollectionReaderAnimationDelegate(
        CollectionReaderPageAnimation.slide,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isA<SlideDelegate>(),
    );
    expect(
      resolveCollectionReaderAnimationDelegate(
        CollectionReaderPageAnimation.simulation,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isA<SimulationDelegate>(),
    );
    expect(
      resolveCollectionReaderAnimationDelegate(
        CollectionReaderPageAnimation.simulation,
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      isA<SlideDelegate>(),
    );
  });

  test('tap regions split viewport into left center and right thirds', () {
    const delegate = NoAnimDelegate();
    const size = Size(300, 600);

    expect(
      delegate.resolveTapRegion(
        details: TapUpDetails(
          localPosition: Offset(40, 200),
          kind: PointerDeviceKind.touch,
        ),
        size: size,
      ),
      CollectionReaderTapRegion.left,
    );
    expect(
      delegate.resolveTapRegion(
        details: TapUpDetails(
          localPosition: Offset(150, 200),
          kind: PointerDeviceKind.touch,
        ),
        size: size,
      ),
      CollectionReaderTapRegion.center,
    );
    expect(
      delegate.resolveTapRegion(
        details: TapUpDetails(
          localPosition: Offset(260, 200),
          kind: PointerDeviceKind.touch,
        ),
        size: size,
      ),
      CollectionReaderTapRegion.right,
    );
  });

  test('tap region actions map left center right to prev menu next', () {
    const delegate = NoAnimDelegate();
    const size = Size(300, 600);
    var prevCount = 0;
    var centerCount = 0;
    var nextCount = 0;

    void resetCounts() {
      prevCount = 0;
      centerCount = 0;
      nextCount = 0;
    }

    delegate.onTapRegion(
      details: TapUpDetails(
        localPosition: Offset(40, 200),
        kind: PointerDeviceKind.touch,
      ),
      size: size,
      tapRegionConfig: CollectionReaderTapRegionConfig.defaults,
      onCenterTap: () => centerCount += 1,
      goPrevPage: () => prevCount += 1,
      goNextPage: () => nextCount += 1,
      goPrevChapter: () {},
      goNextChapter: () {},
      showToc: () {},
      showSearch: () {},
    );
    expect((prevCount, centerCount, nextCount), (1, 0, 0));

    resetCounts();
    delegate.onTapRegion(
      details: TapUpDetails(
        localPosition: Offset(150, 200),
        kind: PointerDeviceKind.touch,
      ),
      size: size,
      tapRegionConfig: CollectionReaderTapRegionConfig.defaults,
      onCenterTap: () => centerCount += 1,
      goPrevPage: () => prevCount += 1,
      goNextPage: () => nextCount += 1,
      goPrevChapter: () {},
      goNextChapter: () {},
      showToc: () {},
      showSearch: () {},
    );
    expect((prevCount, centerCount, nextCount), (0, 1, 0));

    resetCounts();
    delegate.onTapRegion(
      details: TapUpDetails(
        localPosition: Offset(260, 200),
        kind: PointerDeviceKind.touch,
      ),
      size: size,
      tapRegionConfig: CollectionReaderTapRegionConfig.defaults,
      onCenterTap: () => centerCount += 1,
      goPrevPage: () => prevCount += 1,
      goNextPage: () => nextCount += 1,
      goPrevChapter: () {},
      goNextChapter: () {},
      showToc: () {},
      showSearch: () {},
    );
    expect((prevCount, centerCount, nextCount), (0, 0, 1));
  });
}
