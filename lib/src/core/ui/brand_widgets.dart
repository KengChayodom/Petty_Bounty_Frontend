import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_glass.dart';

/// Shared pieces of the photo + glass layout used by every screen that shows
/// one pet or one person: a photo hero, a cream sheet rising over it, a glass
/// back button, and one orange action per screen.

/// A round frosted button that floats over a photo.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.white.withValues(alpha: 0.22),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: IconButton(
            tooltip: tooltip,
            icon: Icon(icon, color: kDaylight, size: 22),
            onPressed: onPressed,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

/// The screen's one main action: deep orange, full width, white label.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// A secondary action: outline only.
  final bool outlined;

  /// An outlined action that says no (dispute, reject).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(27));
    final text = Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
    final child = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 20), const SizedBox(width: 10), text],
          );
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: danger ? kBrandErrorDeep : kBrandDeep,
                side: BorderSide(
                  width: 1.5,
                  color: (danger ? kBrandErrorDeep : kBrandDeep).withValues(alpha: 0.55),
                ),
                shape: shape,
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandDeep,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kInk.withValues(alpha: 0.08),
                disabledForegroundColor: kInk.withValues(alpha: 0.35),
                elevation: 0,
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}

/// A heading inside a sheet: sentence case, no all-caps label.
class SheetHeading extends StatelessWidget {
  const SheetHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
        ),
        ?trailing,
      ],
    );
  }
}

/// A white tile on the cream sheet, the one container shape of these screens.
class SheetTile extends StatelessWidget {
  const SheetTile({super.key, required this.child, this.padding, this.highlight = false});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// An orange outline: the tile that wants the user's attention.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: highlight ? 1.5 : 1,
          color: highlight ? kBrandDeep.withValues(alpha: 0.35) : kInk.withValues(alpha: 0.07),
        ),
      ),
      child: child,
    );
  }
}

/// A pet photo, or a warm placeholder when there is none.
class HeroPhoto extends StatelessWidget {
  const HeroPhoto({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFF4A3426),
      child: Align(
        alignment: Alignment(0, -0.35),
        child: Icon(Icons.pets_rounded, size: 48, color: Color(0x40FFF3E6)),
      ),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// The layout of a one-pet screen: the pet's photo across the top under a
/// dark fade, the [title] written on it, and a cream sheet holding [children]
/// that scrolls up over the photo.
class PhotoHeroScaffold extends StatelessWidget {
  const PhotoHeroScaffold({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailingTitle,
    this.actions = const [],
    this.heroHeight = 340,
    this.onRefresh,
    this.bottom,
  });

  final String? imageUrl;
  final String title;
  final String? subtitle;

  /// Shown at the right of the title on the photo, such as a reward.
  final Widget? trailingTitle;
  final List<Widget> children;
  final List<Widget> actions;
  final double heroHeight;
  final Future<void> Function()? onRefresh;

  /// Pinned under the sheet, such as the screen's main action.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    const overlap = 28.0;
    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: heroHeight - overlap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: displayStyle(size: 40, color: kDaylight)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!,
                            style: TextStyle(
                                fontSize: 15, color: kDaylight.withValues(alpha: 0.88))),
                      ],
                    ],
                  ),
                ),
                if (trailingTitle != null) ...[const SizedBox(width: 12), trailingTitle!],
              ],
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - heroHeight + overlap,
          ),
          decoration: const BoxDecoration(
            color: kDaylight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
    if (onRefresh != null) {
      list = RefreshIndicator.noSpinner(onRefresh: onRefresh!, child: list);
    }

    return Scaffold(
      backgroundColor: kDaylight,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HeroPhoto(imageUrl: imageUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.3, 1],
                      colors: [Color(0x59120A04), Color(0x00120A04), Color(0xB3120A04)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          list,
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                const Spacer(),
                for (final a in actions) ...[const SizedBox(width: 8), a],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottom == null
          ? null
          : Container(
              color: kDaylight,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: bottom,
            ),
    );
  }
}
