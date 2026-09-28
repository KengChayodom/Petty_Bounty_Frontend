import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_glass.dart';

/// A sonar scope centred on the user: a beam that sweeps around, dragging a
/// fading afterglow behind it, inside a ring that marks how far the search
/// actually reaches.
///
/// Anchored to the ground, not to the screen: the radius IS the search radius
/// in metres, so the beam always sweeps exactly as far as the app actually
/// searches and the scope's edge lands on the static radius circle drawn
/// underneath.
///
/// Zoomed in the edge is far off-screen — 10 km is about 2,155 px at the zoom
/// the app opens at — and what you see is the beam sweeping across the whole
/// view. That works here because the beam is a line from the centre: it is on
/// screen for its whole length even when its far end is not. An earlier
/// version of this layer drew expanding concentric rings instead, and those
/// were born and died off-screen at that zoom, which is why they needed a cap
/// and this does not.
///
/// Goes into `FlutterMap.children`.
class UserRadarLayer extends StatefulWidget {
  const UserRadarLayer({
    super.key,
    required this.centre,
    required this.radiusMeters,
    this.period = const Duration(seconds: 10),
  });

  final LatLng centre;

  /// Pass the same value the static search-radius circle uses.
  final double radiusMeters;

  /// One full revolution of the beam. Slow on purpose — this is ambient, and
  /// it shares a screen with map panning and marker taps, so it should never
  /// be the thing drawing the eye.
  final Duration period;

  @override
  State<UserRadarLayer> createState() => _UserRadarLayerState();
}

class _UserRadarLayerState extends State<UserRadarLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Same contract as the auth screens: honour the platform's reduce-motion
    // switch, and never leave a repeating controller running for a widget test
    // to wait on. Held at zero the beam parks pointing east, which is a
    // reasonable thing for the screen to show.
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_clock.isAnimating) {
        _clock
          ..stop()
          ..value = 0;
      }
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // Project the radius due south and measure it in pixels — exactly how
    // flutter_map's own CirclePainter turns metres into screen space.
    final centrePx = camera.project(widget.centre);
    final edgePx = camera.project(
      const Distance().offset(widget.centre, widget.radiusMeters, 180),
    );
    final radius = (edgePx.y - centrePx.y).abs();

    // Isolated: this repaints every frame, and without a boundary it would
    // drag the tile and marker layers into each of those repaints.
    return RepaintBoundary(
      child: MobileLayerTransformer(
        child: CustomPaint(
          size: Size(camera.size.x, camera.size.y),
          painter: _SonarPainter(
            clock: _clock,
            centre: camera.getOffsetFromOrigin(widget.centre),
            radius: radius,
          ),
        ),
      ),
    );
  }
}

class _SonarPainter extends CustomPainter {
  _SonarPainter({
    required this.clock,
    required this.centre,
    required this.radius,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final Offset centre;
  final double radius;

  /// How far the afterglow trails the beam, as a fraction of a turn.
  static const double _tail = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 1) return;
    canvas.clipRect(Offset.zero & size);

    final angle = clock.value * 2 * math.pi;
    final bounds = Rect.fromCircle(center: centre, radius: radius);

    // The afterglow. A sweep gradient whose bright end sits at stop 1.0, then
    // rotated so that stop 1.0 lands on the beam — which puts the fading band
    // BEHIND the beam rather than ahead of it.
    //
    // Kept light: now that the scope reaches the full 10 km, its wedge covers
    // a large part of the view at street zoom rather than a disc in the middle
    // of it.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            kBrand.withValues(alpha: 0),
            kBrand.withValues(alpha: 0),
            kBrand.withValues(alpha: 0.06),
            kBrand.withValues(alpha: 0.18),
          ],
          stops: [0, 1 - _tail, 1 - _tail * 0.18, 1],
          transform: GradientRotation(angle),
        ).createShader(bounds),
    );

    // The beam itself: brightest at the pin, fading as it goes out. The
    // gradient runs along the beam, so it has to be built from the beam's own
    // two ends — a LinearGradient over the circle's bounding box would run
    // left-to-right across the screen no matter which way the beam points.
    final tip = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawLine(
      centre,
      tip,
      Paint()
        ..shader = ui.Gradient.linear(centre, tip, [
          kBrand.withValues(alpha: 0.85),
          kBrand.withValues(alpha: 0.30),
        ])
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // The scope's edge — the search boundary itself — plus a mid range-ring so
    // the beam has something to cross. Both are usually off-screen when zoomed
    // in; the canvas clip means drawing them anyway costs nothing.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kBrand.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      centre,
      radius * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = kBrand.withValues(alpha: 0.14),
    );
  }

  // Decoration only — it must never take a pointer. `RenderCustomPaint`
  // defaults `hitTestSelf` to `painter.hitTest(position) ?? true`.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(covariant _SonarPainter old) =>
      old.clock != clock || old.centre != centre || old.radius != radius;
}
