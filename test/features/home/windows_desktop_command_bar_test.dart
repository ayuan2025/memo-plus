import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/features/home/desktop/windows_desktop_command_bar.dart';

void main() {
  testWidgets('command bar keeps height 46 and renders slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WindowsDesktopCommandBar(
            leading: const Text('Leading'),
            center: const Text('Center'),
            trailing: const Text('Trailing'),
            debugBadgeText: 'API v0.24',
            desktopWindowMaximized: false,
            onMinimize: () {},
            onToggleMaximize: () {},
            onClose: () {},
            minimizeTooltip: 'Minimize',
            maximizeTooltip: 'Maximize',
            restoreTooltip: 'Restore',
            closeTooltip: 'Close',
          ),
        ),
      ),
    );

    final commandBar = tester.getSize(
      find.byKey(const ValueKey<String>('windows-desktop-command-bar')),
    );
    expect(commandBar.height, 46);
    expect(find.text('Leading'), findsOneWidget);
    expect(find.text('Center'), findsOneWidget);
    expect(find.text('Trailing'), findsOneWidget);
    expect(find.text('API v0.24'), findsOneWidget);
  });

  testWidgets('command bar window controls expose tooltips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WindowsDesktopCommandBar(
            leading: const SizedBox.shrink(),
            center: const SizedBox.shrink(),
            trailing: const SizedBox.shrink(),
            desktopWindowMaximized: true,
            onMinimize: () {},
            onToggleMaximize: () {},
            onClose: () {},
            minimizeTooltip: 'Minimize',
            maximizeTooltip: 'Maximize',
            restoreTooltip: 'Restore',
            closeTooltip: 'Close',
          ),
        ),
      ),
    );

    expect(find.byTooltip('Minimize'), findsOneWidget);
    expect(find.byTooltip('Restore'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
  });
}
