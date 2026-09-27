import 'package:flutter/material.dart';

import '../../core/desktop/desktop_titlebar_navigation_policy.dart';
import '../../core/desktop/window_chrome_safe_area.dart';

class MemoDetailView extends StatelessWidget {
  const MemoDetailView({
    super.key,
    required this.backgroundColor,
    required this.child,
    this.embedded = false,
    this.embeddedHeader,
    this.title,
    this.actions,
    this.backgroundChild,
  });

  final Color backgroundColor;
  final Widget child;
  final bool embedded;
  final Widget? embeddedHeader;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? backgroundChild;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final chromeInsets = resolveDesktopWindowChromeInsets(
      platform: platform,
      contentExtendsIntoTitleBar: true,
    );
    final needsChromeLeadingInset = chromeInsets.leading > 0;
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    final automaticallyImplyLeading =
        resolveDesktopRouteAutomaticallyImplyLeading(
          context: context,
          automaticallyImplyLeading: true,
        );
    final impliedChromeLeading =
        needsChromeLeadingInset && automaticallyImplyLeading && routeCanPop
        ? const BackButton()
        : null;
    final appBarLeading = impliedChromeLeading == null
        ? null
        : DesktopWindowChromeSafeArea(
            contentExtendsIntoTitleBar: true,
            platform: platform,
            includeTop: false,
            includeTrailing: false,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: impliedChromeLeading,
            ),
          );
    final appBarLeadingWidth = appBarLeading == null
        ? null
        : kToolbarHeight + chromeInsets.leading;
    final appBarTitleSpacing = needsChromeLeadingInset && appBarLeading == null
        ? NavigationToolbar.kMiddleSpacing + chromeInsets.leading
        : null;

    if (embedded) {
      return ColoredBox(
        color: backgroundColor,
        child: Column(
          children: [
            if (embeddedHeader != null) embeddedHeader!,
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: chromeInsets.top > 0
            ? kToolbarHeight + chromeInsets.top
            : null,
        leading: appBarLeading,
        leadingWidth: appBarLeadingWidth,
        titleSpacing: appBarTitleSpacing,
        automaticallyImplyLeading: needsChromeLeadingInset
            ? false
            : automaticallyImplyLeading,
        title: title,
        actions: actions,
      ),
      body: Stack(
        children: [
          if (backgroundChild != null) Positioned.fill(child: backgroundChild!),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
