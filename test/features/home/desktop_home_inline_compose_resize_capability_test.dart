import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/home/desktop_home_inline_compose_resize_capability.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';

void main() {
  test('desktop home-local day filter can preserve inline compose resize', () {
    final day = DateTime(2026, 6, 7);

    final routeLevelDayPage =
        shouldEnableDesktopHomeInlineComposeResizeForMemosList(
          platform: TargetPlatform.windows,
          presentation: HomeScreenPresentation.standalone,
          navigationHost: null,
          explicitlyEnabled: false,
          showDrawer: true,
          enableCompose: true,
          state: 'NORMAL',
          tag: null,
          dayFilter: day,
        );
    final homeLocalDayFilter =
        shouldEnableDesktopHomeInlineComposeResizeForMemosList(
          platform: TargetPlatform.windows,
          presentation: HomeScreenPresentation.standalone,
          navigationHost: null,
          explicitlyEnabled: false,
          showDrawer: true,
          enableCompose: true,
          state: 'NORMAL',
          tag: null,
          dayFilter: day,
          allowFilteredHomeInlineComposeResize: true,
        );

    expect(routeLevelDayPage, isFalse);
    expect(homeLocalDayFilter, isTrue);
  });

  test('unsupported platforms keep resize disabled for day filters', () {
    final enabled = shouldEnableDesktopHomeInlineComposeResizeForMemosList(
      platform: TargetPlatform.android,
      presentation: HomeScreenPresentation.standalone,
      navigationHost: null,
      explicitlyEnabled: false,
      showDrawer: true,
      enableCompose: true,
      state: 'NORMAL',
      tag: null,
      dayFilter: DateTime(2026, 6, 7),
      allowFilteredHomeInlineComposeResize: true,
    );

    expect(enabled, isFalse);
  });
}
