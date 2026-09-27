import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/desktop/desktop_titlebar_navigation_policy.dart';
import '../../core/desktop/window_chrome_safe_area.dart';
import '../platform_target.dart';

class PlatformPage extends StatelessWidget {
  const PlatformPage({
    super.key,
    required this.body,
    this.title,
    this.centerTitle,
    this.leading,
    this.actions,
    this.bottomBar,
    this.drawer,
    this.drawerEnableOpenDragGesture = true,
    this.sidebar,
    this.toolbar,
    this.safeArea = true,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.desktopNavigationMode,
    this.desktopNavigationContext,
    this.desktopWindowChromeSafeArea = false,
  });

  final Widget body;
  final Widget? title;
  final bool? centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final Widget? drawer;
  final bool drawerEnableOpenDragGesture;
  final Widget? sidebar;
  final Widget? toolbar;
  final bool safeArea;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final DesktopTitlebarNavigationMode? desktopNavigationMode;
  final DesktopTitlebarNavigationContext? desktopNavigationContext;
  final bool desktopWindowChromeSafeArea;

  @override
  Widget build(BuildContext context) {
    final target = resolvePlatformTarget(context);
    final bodyWidget = safeArea ? SafeArea(child: body) : body;

    if (target == PlatformTarget.iPhone || target == PlatformTarget.iPad) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar:
            title == null && leading == null && (actions?.isEmpty ?? true)
            ? null
            : CupertinoNavigationBar(
                middle: title,
                leading: leading,
                trailing: actions == null
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
        child: Column(
          children: [
            if (toolbar != null) toolbar!,
            Expanded(child: bodyWidget),
            if (bottomBar != null) bottomBar!,
          ],
        ),
      );
    }

    final navigationContext =
        desktopNavigationContext ??
        resolveDesktopTitlebarNavigationContext(context);
    final navigationMode =
        desktopNavigationMode ?? DesktopTitlebarNavigationMode.hidden;
    final platform = switch (target) {
      PlatformTarget.macOS => TargetPlatform.macOS,
      PlatformTarget.windows => TargetPlatform.windows,
      PlatformTarget.linux => TargetPlatform.linux,
      _ => Theme.of(context).platform,
    };
    final effectiveTitle = resolveDesktopTopLevelTitle(
      platform: platform,
      navigationMode: navigationMode,
      navigationContext: navigationContext,
      title: title,
    );
    final topLevelChromeOmitted = shouldOmitDesktopTopLevelChrome(
      platform: platform,
      navigationMode: navigationMode,
      navigationContext: navigationContext,
    );
    final omitRouteDismissalControl = shouldOmitDesktopRouteDismissalControl(
      platform: platform,
      navigationContext: navigationContext,
    );
    final effectiveLeading = omitRouteDismissalControl || topLevelChromeOmitted
        ? null
        : leading;
    final automaticallyImplyLeading =
        !omitRouteDismissalControl && !topLevelChromeOmitted;
    final effectiveToolbarHeight = resolveDesktopTopLevelToolbarHeight(
      platform: platform,
      navigationMode: navigationMode,
      navigationContext: navigationContext,
    );
    final chromeInsets = resolveDesktopWindowChromeInsets(
      platform: platform,
      contentExtendsIntoTitleBar: desktopWindowChromeSafeArea,
    );
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    final needsChromeLeadingInset = chromeInsets.leading > 0;
    final impliedChromeLeading =
        needsChromeLeadingInset &&
            effectiveLeading == null &&
            automaticallyImplyLeading &&
            routeCanPop
        ? const BackButton()
        : null;
    final appBarLeadingChild = effectiveLeading ?? impliedChromeLeading;
    final appBarLeading = needsChromeLeadingInset && appBarLeadingChild != null
        ? DesktopWindowChromeSafeArea(
            contentExtendsIntoTitleBar: true,
            platform: platform,
            includeTop: false,
            includeTrailing: false,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: appBarLeadingChild,
            ),
          )
        : effectiveLeading;
    final appBarLeadingWidth =
        needsChromeLeadingInset && appBarLeadingChild != null
        ? kToolbarHeight + chromeInsets.leading
        : null;
    final appBarTitleSpacing =
        needsChromeLeadingInset && appBarLeadingChild == null
        ? NavigationToolbar.kMiddleSpacing + chromeInsets.leading
        : null;
    final appBarAutomaticallyImplyLeading = needsChromeLeadingInset
        ? false
        : automaticallyImplyLeading;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar:
          !topLevelChromeOmitted &&
              effectiveTitle == null &&
              effectiveLeading == null &&
              (actions?.isEmpty ?? true)
          ? null
          : AppBar(
              toolbarHeight: effectiveToolbarHeight,
              title: effectiveTitle,
              centerTitle: centerTitle,
              leading: appBarLeading,
              leadingWidth: appBarLeadingWidth,
              titleSpacing: appBarTitleSpacing,
              automaticallyImplyLeading: appBarAutomaticallyImplyLeading,
              actions: actions,
            ),
      drawer: drawer,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      body: Column(
        children: [
          if (toolbar != null) toolbar!,
          Expanded(
            child: Row(
              children: [
                if (sidebar != null) sidebar!,
                Expanded(child: bodyWidget),
              ],
            ),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}
