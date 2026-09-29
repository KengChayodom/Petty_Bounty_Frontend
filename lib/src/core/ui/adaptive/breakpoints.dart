import 'package:flutter/material.dart';

/// Material 3 window size classes, by width in logical pixels.
///
/// Decide layout from the space the app is actually given ([MediaQuery.sizeOf]
/// or a [LayoutBuilder]), never from the device model. That keeps iPad Split
/// View, Slide Over and rotation working, because the window can be phone-sized
/// on an iPad.
enum WindowSize {
  /// Under 600: phones in portrait.
  compact,

  /// 600 to 839: iPad portrait, split view halves.
  medium,

  /// 840 and up: iPad landscape, large iPad portrait.
  expanded;

  static const double mediumStart = 600;
  static const double expandedStart = 840;

  static WindowSize fromWidth(double width) {
    if (width >= expandedStart) return WindowSize.expanded;
    if (width >= mediumStart) return WindowSize.medium;
    return WindowSize.compact;
  }

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSize.compact;
}

/// Widest a floating pane over the map (search card, bottom nav) may get.
const double kFloatingChromeMaxWidth = 520;

/// Widest a reading column (list, form, detail) is allowed to get.
const double kContentMaxWidth = 640;

/// Centres [child] and caps its width at [maxWidth].
///
/// Wrap a screen's `body` in this, not the whole `Scaffold`, so the page
/// background and app bar still span the full width while the content stays a
/// readable column. A phone never reaches the cap, so phone layouts are
/// unchanged. Full-bleed screens (map, camera) should not use it.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
