import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/desktop_layout_policy.dart';
import 'package:memos_flutter_app/core/desktop/desktop_surface_policy.dart';

void main() {
  test('Windows supports resizable inline and overlay secondary panes', () {
    final layout = resolveDesktopLayoutPolicy(
      1360,
      platform: TargetPlatform.windows,
    );

    final policy = resolveDesktopSurfacePolicy(
      platform: TargetPlatform.windows,
      layoutSpec: layout,
      secondaryPaneAvailable: true,
      secondaryPaneVisible: true,
      secondaryPaneWidth: 999,
      requestedSecondaryPanePresentation: DesktopPanePresentation.overlay,
      secondaryPaneResizeRequested: true,
      modalSurfaceAvailable: false,
      modalSurfaceVisible: false,
      modalBarrierColor: Colors.black,
      modalBarrierBlurSigma: 14,
    );

    expect(policy.secondaryPane.supported, isTrue);
    expect(policy.secondaryPane.visible, isTrue);
    expect(policy.secondaryPane.presentation, DesktopPanePresentation.overlay);
    expect(policy.secondaryPane.width, kWindowsDesktopSecondaryPaneMaxWidth);
    expect(policy.secondaryPane.resizable, isTrue);
    expect(policy.secondaryPane.supportsMotion, isTrue);
  });

  test('macOS supports inline secondary pane without resize motion parity', () {
    final layout = resolveDesktopLayoutPolicy(
      1360,
      platform: TargetPlatform.macOS,
    );

    final policy = resolveDesktopSurfacePolicy(
      platform: TargetPlatform.macOS,
      layoutSpec: layout,
      secondaryPaneAvailable: true,
      secondaryPaneVisible: true,
      secondaryPaneWidth: 420,
      requestedSecondaryPanePresentation: DesktopPanePresentation.inline,
      secondaryPaneResizeRequested: true,
      modalSurfaceAvailable: true,
      modalSurfaceVisible: true,
      modalBarrierColor: Colors.black,
      modalBarrierBlurSigma: 14,
    );

    expect(policy.secondaryPane.supported, isTrue);
    expect(policy.secondaryPane.visible, isTrue);
    expect(policy.secondaryPane.presentation, DesktopPanePresentation.inline);
    expect(policy.secondaryPane.resizable, isFalse);
    expect(policy.secondaryPane.supportsMotion, isFalse);
    expect(policy.modalSurface.visible, isTrue);
    expect(policy.modalSurface.barrierBlurSigma, 0);
    expect(policy.modalSurface.supportsMotion, isFalse);
  });

  test('macOS overlay secondary pane is an explicit unsupported fallback', () {
    final layout = resolveDesktopLayoutPolicy(
      1360,
      platform: TargetPlatform.macOS,
    );

    final policy = resolveDesktopSurfacePolicy(
      platform: TargetPlatform.macOS,
      layoutSpec: layout,
      secondaryPaneAvailable: true,
      secondaryPaneVisible: true,
      secondaryPaneWidth: 420,
      requestedSecondaryPanePresentation: DesktopPanePresentation.overlay,
      secondaryPaneResizeRequested: false,
      modalSurfaceAvailable: false,
      modalSurfaceVisible: false,
      modalBarrierColor: Colors.black,
      modalBarrierBlurSigma: 14,
    );

    expect(policy.secondaryPane.supported, isFalse);
    expect(policy.secondaryPane.visible, isFalse);
    expect(
      policy.secondaryPane.presentation,
      DesktopPanePresentation.unsupported,
    );
  });
}
