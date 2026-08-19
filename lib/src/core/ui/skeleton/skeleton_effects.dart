import 'package:skeletonizer/skeletonizer.dart';

/// Every skeleton palette in the app, in one place.
///
/// This app renders **no** loading indicators — no spinner, no
/// `CircularProgressIndicator`, no `LinearProgressIndicator`. Pending state is
/// always communicated by a skeleton of the layout that is about to appear,
/// driven by `package:skeletonizer`.
///
/// Three palettes exist because skeletons are painted onto three very
/// different surfaces, and a single grey cannot read on all of them:
///   * [onSurface] — the app's light `0xFFF9FAFB` / white content surfaces;
///   * [onAccent]  — *inside* a saturated brand button while its action runs;
///   * [onDark]    — the camera / full-screen-photo surfaces, which are black.
///
/// `Color` is available here because the skeletonizer barrel re-exports
/// `package:flutter/painting.dart`.
abstract final class AppSkeletons {
  /// Grey-on-light: the default for content skeletons. Registered app-wide as
  /// a `ThemeExtension` (see [config] and `main.dart`), so a bare
  /// `Skeletonizer(child: ...)` anywhere in the app picks it up automatically.
  static const ShimmerEffect onSurface = ShimmerEffect(
    baseColor: Color(0xFFE7EAEE),
    highlightColor: Color(0xFFF5F7F9),
  );

  /// Translucent-white-on-brand, for the placeholder that stands in for a
  /// button's label while its action is in flight (see `BusyButtonLabel`).
  /// Alpha-based so it works on every button colour the app uses — orange
  /// `0xFFED7645`, blue `0xFF0022FF`, green `0xFF4CAF7D`.
  static const ShimmerEffect onAccent = ShimmerEffect(
    baseColor: Color(0x4DFFFFFF),
    highlightColor: Color(0xB3FFFFFF),
  );

  /// Translucent-white-on-black, for the camera preview, the full-screen photo
  /// viewer, and the "AI is analyzing" scrim drawn over a photo.
  static const ShimmerEffect onDark = ShimmerEffect(
    baseColor: Color(0x2EFFFFFF),
    highlightColor: Color(0x5CFFFFFF),
  );

  /// The app-wide skeleton config, registered in `ThemeData.extensions`.
  ///
  /// `ignoreContainers: false` is deliberate: the app's cards are plain
  /// `Container`s with a `BoxDecoration`, and letting skeletonizer paint them
  /// keeps a loading card the same silhouette as a loaded one.
  static const SkeletonizerConfigData config = SkeletonizerConfigData(
    effect: onSurface,
    ignoreContainers: false,
    justifyMultiLineText: true,
  );
}
