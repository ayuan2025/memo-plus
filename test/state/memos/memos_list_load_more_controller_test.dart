import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/state/memos/memos_list_load_more_controller.dart';

void main() {
  group('MemosListLoadMoreController', () {
    test('syncQueryKey resets pagination and transient load state', () {
      final controller = MemosListLoadMoreController(
        initialPageSize: 20,
        pageStep: 20,
      );

      controller.updateSnapshot(
        hasProviderValue: true,
        resultCount: 20,
        providerLoading: false,
        showSearchLanding: false,
      );
      controller.beginLoadMore(source: 'scroll');
      controller.updateTouchPullDistance(48, threshold: 24);
      controller.shouldThrottleDesktopWheel(
        DateTime(2025, 1, 1, 12),
        const Duration(milliseconds: 300),
      );

      final changed = controller.syncQueryKey(
        'tag=work',
        previousVisibleCount: 20,
      );

      expect(changed, isTrue);
      expect(controller.pageSize, 20);
      expect(controller.reachedEnd, isFalse);
      expect(controller.loadingMore, isFalse);
      expect(controller.lastResultCount, 0);
      expect(controller.mobileBottomPullDistance, 0);
      expect(controller.mobileBottomPullArmed, isFalse);
      expect(controller.activeLoadMoreRequestId, isNull);
      expect(controller.activeLoadMoreSource, isNull);
    });

    test('updateSnapshot marks reachedEnd when result count is below page size', () {
      final controller = MemosListLoadMoreController(
        initialPageSize: 20,
        pageStep: 20,
      );

      controller.updateSnapshot(
        hasProviderValue: true,
        resultCount: 20,
        providerLoading: false,
        showSearchLanding: false,
      );
      expect(controller.reachedEnd, isFalse);

      controller.beginLoadMore(source: 'button');
      expect(controller.pageSize, 40);

      controller.updateSnapshot(
        hasProviderValue: true,
        resultCount: 35,
        providerLoading: false,
        showSearchLanding: false,
      );

      expect(controller.currentResultCount, 35);
      expect(controller.lastResultCount, 35);
      expect(controller.loadingMore, isFalse);
      expect(controller.reachedEnd, isTrue);
    });

    test('beginLoadMore increments request id and tracks source until finish', () {
      final controller = MemosListLoadMoreController(
        initialPageSize: 20,
        pageStep: 10,
      );

      final first = controller.beginLoadMore(source: 'scroll');
      expect(first, 1);
      expect(controller.loadingMore, isTrue);
      expect(controller.pageSize, 30);
      expect(controller.activeLoadMoreRequestId, 1);
      expect(controller.activeLoadMoreSource, 'scroll');

      controller.finishLoadMore();
      expect(controller.loadingMore, isFalse);
      expect(controller.activeLoadMoreRequestId, isNull);
      expect(controller.activeLoadMoreSource, isNull);

      final second = controller.beginLoadMore(source: 'button');
      expect(second, 2);
      expect(controller.activeLoadMoreRequestId, 2);
      expect(controller.activeLoadMoreSource, 'button');
    });

    test('tracks touch pull arm state and resets after consume', () {
      final controller = MemosListLoadMoreController(
        initialPageSize: 20,
        pageStep: 20,
      );

      controller.updateTouchPullDistance(12, threshold: 24);
      expect(controller.mobileBottomPullArmed, isFalse);

      controller.updateTouchPullDistance(36, threshold: 24);
      expect(controller.mobileBottomPullArmed, isTrue);
      expect(controller.mobileBottomPullDistance, 36);

      expect(controller.consumeTouchPullArm(), isTrue);
      expect(controller.mobileBottomPullDistance, 0);
      expect(controller.mobileBottomPullArmed, isFalse);
    });

    test('throttles desktop wheel events inside debounce window', () {
      final controller = MemosListLoadMoreController(
        initialPageSize: 20,
        pageStep: 20,
      );
      final start = DateTime(2025, 1, 1, 12, 0, 0);

      expect(
        controller.shouldThrottleDesktopWheel(
          start,
          const Duration(milliseconds: 300),
        ),
        isFalse,
      );
      expect(
        controller.shouldThrottleDesktopWheel(
          start.add(const Duration(milliseconds: 200)),
          const Duration(milliseconds: 300),
        ),
        isTrue,
      );
      expect(
        controller.shouldThrottleDesktopWheel(
          start.add(const Duration(milliseconds: 400)),
          const Duration(milliseconds: 300),
        ),
        isFalse,
      );
    });
  });
}
