import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/ui/skeleton/skeleton.dart';

/// Immersive shell for the Login screen: a full-bleed backdrop under a dark
/// scrim, with the form floating above it on a frosted-glass card.
///
/// Presentation-only — no auth logic lives here. The screen keeps its
/// controllers, validators and submit handler and just composes these pieces.
///
/// Shared by Login and Register — `compact` trims the header for the longer
/// of the two forms.

/// Shared by the card and by the float that casts its shadow, so the lifted
/// card and the shadow it leaves behind keep the same corner.
const BorderRadius _kCardRadius = BorderRadius.all(Radius.circular(28));

/// Drop any photo here — a dog on a street, a cat on a wall — and it becomes
/// the backdrop on the next build. Until the file exists, [_PaintedBackdrop]
/// stands in, so the screen is never waiting on an asset to look finished.
const String kAuthBackdropAsset = 'assets/auth_bg.jpg';

const String _kLogoAsset = 'assets/Petty Bounty Logo.png';

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

class GlassAuthScaffold extends StatelessWidget {
  const GlassAuthScaffold({
    super.key,
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.compact = false,
    this.onBack,
  });

  /// The owning screen's form key — wraps [children] so the screen's
  /// `validate()` reaches these fields.
  final GlobalKey<FormState> formKey;

  /// Card heading, e.g. "Welcome back".
  final String title;

  /// Card sub-heading, e.g. "Sign in to keep the search going".
  final String subtitle;

  /// Fields, error text and primary button — laid out (stretched) on the card.
  final List<Widget> children;

  /// Sits below the card, outside the glass (the register link).
  final Widget? footer;

  /// Shrinks the brandmark and drops the tagline. Set it on a long form, where
  /// a full-height header would push the first field off the screen.
  final bool compact;

  /// Renders a back affordance over the backdrop. Supply it on a screen that
  /// was pushed onto another; a root screen leaves it null.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // The OS paints the status bar over this screen, and its icons default to
    // light — invisible on a cream backdrop. `dark` here means dark icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kDaylight,
        body: _Ambient(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _Backdrop(),
              const _Scrim(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Centre the column on a tall screen, but let it scroll away
                    // from the keyboard on a short one.
                    final minHeight = math.max(0.0, constraints.maxHeight - 44);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: ConstrainedBox(
                            // Keeps the card a card on a tablet instead of an
                            // 800px-wide letterbox.
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _Entrance(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Brandmark(compact: compact),
                                  SizedBox(height: compact ? 22 : 30),
                                  // Deliberately not floating. The brandmark and
                                  // the backdrop carry the motion; the card is
                                  // what the user is reading and typing into, so
                                  // it stays put.
                                  _GlassCard(
                                    formKey: formKey,
                                    title: title,
                                    subtitle: subtitle,
                                    children: children,
                                  ),
                                  if (footer != null) ...[
                                    const SizedBox(height: 24),
                                    footer!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (onBack != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: kInk,
                        tooltip: 'Back',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short rise the first time the screen is built. One-shot: it must
/// terminate, or `pumpAndSettle` in the widget tests would never return.
///
/// A rise and not a fade: the card underneath is a `BackdropFilter`, and an
/// opacity layer over one makes Impeller log
/// `Contents::SetInheritedOpacity should never be called when
/// Contents::CanAcceptOpacity returns false` and fall back to an offscreen
/// pass. Ramping the blur sigma would be the way to bring a fade back.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(0, (1 - t) * 20), child: child),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Ambient motion
// ---------------------------------------------------------------------------

/// One clock for every drifting thing on the screen. A single controller keeps
/// the backdrop, the brandmark and the card on the same timeline, and gives one
/// place to switch the whole effect off.
class _Ambient extends StatefulWidget {
  const _Ambient({required this.child});

  final Widget child;

  @override
  State<_Ambient> createState() => _AmbientState();
}

class _AmbientState extends State<_Ambient>
    with SingleTickerProviderStateMixin {
  /// Every consumer runs a whole number of cycles per turn, so the loop closes
  /// on itself and nothing jumps at the seam.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the platform's "reduce motion" switch. The widget tests turn it
    // on as well, because `pumpAndSettle` waits for the frame queue to drain
    // and a repeating controller never lets that happen.
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
  Widget build(BuildContext context) =>
      _AmbientClock(clock: _clock, child: widget.child);
}

class _AmbientClock extends InheritedWidget {
  const _AmbientClock({required this.clock, required super.child});

  /// Runs 0 -> 1 per turn. Consumers multiply it by their own whole cycle
  /// count and offset it by a phase.
  final Animation<double> clock;

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AmbientClock>()!.clock;

  @override
  bool updateShouldNotify(_AmbientClock oldWidget) => oldWidget.clock != clock;
}

/// Bobs [child] on the ambient clock, optionally casting a shadow from the
/// resting position.
///
/// The shadow is deliberately drawn outside the transform: it stays put while
/// the child rises off it, which is what separates "floating" from "the whole
/// block is sliding up and down".
class _Float extends StatelessWidget {
  const _Float({
    required this.cycles,
    required this.child,
    this.amplitude = 6,
    this.shadows,
    this.borderRadius = BorderRadius.zero,
  });

  /// Whole cycles per turn of the ambient clock.
  final int cycles;

  /// Peak travel in logical pixels.
  final double amplitude;

  /// Called with the current lift, 1 at the top of the bob and -1 at the
  /// bottom, so the shadow can spread and fade as the child rises.
  final List<BoxShadow> Function(double lift)? shadows;

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = _AmbientClock.of(context);
    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final lift = math.sin(clock.value * cycles * 2 * math.pi);
        final lifted = Transform.translate(
          offset: Offset(0, -lift * amplitude),
          child: child,
        );
        final cast = shadows;
        if (cast == null) return lifted;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: cast(lift),
          ),
          child: lifted,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Backdrop
// ---------------------------------------------------------------------------

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final clock = _AmbientClock.of(context);
    return AnimatedBuilder(
      animation: clock,
      builder: (context, child) {
        // A slow push-in and sway, so a supplied photo drifts like the painted
        // fallback does instead of sitting dead still behind moving glass.
        final t = clock.value * 2 * math.pi;
        // Scaled up first so the sway never drags an edge into view.
        return Transform.scale(
          scale: 1.06,
          child: Transform.translate(
            offset: Offset(math.sin(t) * 10, math.cos(t) * 8),
            child: child,
          ),
        );
      },
      child: Image.asset(
        kAuthBackdropAsset,
        fit: BoxFit.cover,
        // The asset is optional by design (see [kAuthBackdropAsset]); a
        // missing file is the normal case, not a failure, so it falls
        // through quietly.
        errorBuilder: (_, _, _) => const _PaintedBackdrop(),
      ),
    );
  }
}

/// The stand-in backdrop: a dusk gradient with out-of-focus light and a few
/// paw prints drifting through it. Blurry by construction, which is what gives
/// the glass card something to refract when no photo is present.
class _PaintedBackdrop extends StatelessWidget {
  const _PaintedBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF5), // first light
            Color(0xFFFFE6C9), // warm haze
            Color(0xFFFFC98F), // low sun
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Out-of-focus highlights — the bokeh a real photo would provide.
          // Each drifts on its own cycle and axis; equal cycles would make the
          // three read as one moving sheet.
          const _Glow(
            top: -110,
            left: -80,
            size: 320,
            color: Color(0x59FFFFFF),
            cycles: 1,
            drift: Offset(26, 18),
          ),
          const _Glow(
            top: 120,
            right: -120,
            size: 340,
            color: Color(0x4DFFAE6B),
            cycles: 2,
            phase: 0.33,
            drift: Offset(-18, 26),
          ),
          const _Glow(
            bottom: -140,
            left: -60,
            size: 400,
            color: Color(0x66FFD9A8),
            cycles: 1,
            phase: 0.6,
            drift: Offset(22, -20),
          ),
          CustomPaint(
            painter: _PawPrintPainter(_AmbientClock.of(context)),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    this.cycles = 1,
    this.phase = 0,
    this.drift = Offset.zero,
  });

  final double? top, left, right, bottom;
  final double size;
  final Color color;

  /// Whole cycles per turn of the ambient clock — an integer, so the loop
  /// closes without a jump.
  final int cycles;
  final double phase;

  /// Peak travel on each axis. The two axes run a quarter-turn apart, which
  /// traces an ellipse rather than a straight line.
  final Offset drift;

  @override
  Widget build(BuildContext context) {
    final clock = _AmbientClock.of(context);
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, child) {
          final t = (clock.value * cycles + phase) * 2 * math.pi;
          return Transform.translate(
            offset: Offset(math.sin(t) * drift.dx, math.cos(t) * drift.dy),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint paw prints, placed on fractions of the canvas so they hold their
/// composition from a small phone up to a tablet.
class _PawPrintPainter extends CustomPainter {
  /// Repaints off the ambient clock rather than off a rebuild, so the drift
  /// costs a paint per frame and nothing else.
  _PawPrintPainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  // (dx, dy, diameter-as-fraction-of-width, rotation in turns, opacity,
  //  drift cycles, drift phase, drift radius in px)
  static const List<List<double>> _paws = [
    [0.72, 0.09, 0.26, -0.06, 0.09, 1, 0.00, 16],
    [0.22, 0.27, 0.20, 0.10, 0.07, 1, 0.40, 22],
    [0.84, 0.52, 0.17, 0.04, 0.06, 2, 0.70, 12],
    [0.16, 0.62, 0.23, -0.12, 0.05, 1, 0.15, 18],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _paws) {
      final t = (clock.value * p[5] + p[6]) * 2 * math.pi;
      _paw(
        canvas,
        Offset(
          size.width * p[0] + math.sin(t) * p[7],
          size.height * p[1] + math.cos(t) * p[7] * 0.8,
        ),
        size.width * p[2],
        // The drift tilts the print a little as it goes, so it reads as
        // floating rather than as sliding on rails.
        p[3] * 2 * math.pi + math.sin(t) * 0.05,
        Paint()..color = kInk.withValues(alpha: p[4] * 0.55),
      );
    }
  }

  /// One paw: four toes on an arc above a rounded pad.
  void _paw(
    Canvas canvas,
    Offset centre,
    double d,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, d * 0.20),
        width: d * 0.62,
        height: d * 0.52,
      ),
      paint,
    );

    // Toes sweep from upper-left to upper-right; the outer two sit lower and
    // smaller, the way a real pad reads.
    const toes = [
      [-0.34, -0.20, 0.19, 0.25],
      [-0.14, -0.34, 0.20, 0.27],
      [0.12, -0.34, 0.20, 0.27],
      [0.32, -0.19, 0.19, 0.25],
    ];
    for (final t in toes) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(d * t[0], d * t[1]),
          width: d * t[2],
          height: d * t[3],
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawPrintPainter oldDelegate) =>
      oldDelegate.clock != clock;
}

/// Darkens the backdrop enough for white type to clear WCAG AA, heaviest at the
/// bottom where the card and the footer link sit.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0DFFFFFF), Color(0x4DFFFFFF), Color(0x91FFFFFF)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

class _Brandmark extends StatelessWidget {
  const _Brandmark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tile = compact ? 64.0 : 88.0;
    return Column(
      children: [
        // An app-icon tile, not a glass disc: the logo PNG is opaque RGB with
        // a white plate baked in, so anything that let the backdrop through
        // behind it would show that plate as a white square.
        Center(
          child: _Float(
            // A shorter cycle than the card's, so the two never rise together.
            cycles: 6,
            amplitude: 5,
            borderRadius: BorderRadius.all(Radius.circular(compact ? 19 : 26)),
            shadows: (lift) => [
              BoxShadow(
                color: kBrand.withValues(alpha: 0.45 - lift * 0.08),
                blurRadius: 40 + lift * 12,
                spreadRadius: -6,
                offset: Offset(0, 14 + lift * 6),
              ),
              BoxShadow(
                color: kInk.withValues(alpha: 0.16 - lift * 0.04),
                blurRadius: 24 + lift * 8,
                offset: Offset(0, 10 + lift * 5),
              ),
            ],
            child: Container(
              width: tile,
              height: tile,
              padding: EdgeInsets.all(compact ? 5 : 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(compact ? 19 : 26),
                ),
              ),
              child: Image.asset(
                _kLogoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.pets, color: kBrand, size: 44),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          'Petty Bounty',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kInk,
            fontSize: compact ? 26 : 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'Bring them home.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kInk.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Glass card
// ---------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const radius = _kCardRadius;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x24AD6A2E),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1,
              ),
              // A touch brighter at the top edge, so the pane catches light
              // rather than reading as flat translucent grey.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.62),
                ],
              ),
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kInk.withValues(alpha: 0.62),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form controls
// ---------------------------------------------------------------------------

/// A translucent field with a leading icon and a floating label. When
/// [obscureText] is set it grows its own show/hide toggle — the old screen made
/// users retype a password they could never see.
class GlassAuthField extends StatefulWidget {
  const GlassAuthField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;

  /// Supply one when the previous field has to hand focus on; otherwise the
  /// field owns (and disposes) its own.
  final FocusNode? focusNode;

  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  /// A hard cap at the UI. The character counter it would normally switch on
  /// is suppressed — it is noise on a field the user cannot overrun.
  final int? maxLength;

  final TextCapitalization textCapitalization;

  @override
  State<GlassAuthField> createState() => _GlassAuthFieldState();
}

class _GlassAuthFieldState extends State<GlassAuthField> {
  late final FocusNode _focusNode = (widget.focusNode ?? FocusNode())
    ..addListener(_onFocusChanged);
  late bool _obscured = widget.obscureText;
  bool _focused = false;

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    // Only ours to dispose when we made it — a caller-owned node outlives us.
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: color, width: width),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        cursorColor: kBrand,
        style: const TextStyle(
          color: kInk,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: _focused ? 0.95 : 0.78),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 20,
            color: _focused ? kBrandDeep : kInk.withValues(alpha: 0.45),
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: kInk.withValues(alpha: 0.45),
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                )
              : null,
          labelStyle: TextStyle(
            color: kInk.withValues(alpha: 0.5),
            fontSize: 15,
          ),
          // Resolved per state rather than fixed: a floating label is shown by
          // any filled field, and colouring every one brand-orange would make
          // the whole form look focused at once.
          floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
            final Color color;
            if (states.contains(WidgetState.error)) {
              color = kBrandErrorDeep;
            } else if (states.contains(WidgetState.focused)) {
              color = kBrandDeep;
            } else {
              color = kInk.withValues(alpha: 0.5);
            }
            return TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            );
          }),
          errorStyle: const TextStyle(
            color: kBrandErrorDeep,
            fontWeight: FontWeight.w500,
          ),
          border: border(kInk.withValues(alpha: 0.12), 1),
          enabledBorder: border(kInk.withValues(alpha: 0.12), 1),
          focusedBorder: border(kBrandDeep, 1.5),
          errorBorder: border(kBrandErrorDeep.withValues(alpha: 0.6), 1),
          focusedErrorBorder: border(kBrandErrorDeep, 1.5),
        ),
      ),
    );
  }
}

/// Full-width pill in the brand gradient. Stays an [ElevatedButton] so it keeps
/// Material's ink, focus and semantics; the gradient rides underneath it.
class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.7,
      duration: const Duration(milliseconds: 180),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(27)),
          gradient: const LinearGradient(
            colors: [kBrandLight, kBrand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: enabled
              ? [
                  // Heavily inset and pushed well below the pill. A shadow
                  // that starts at the pill's own edge rims it in dark orange
                  // and reads as a moulded 3D lip; this one only ever emerges
                  // underneath, as a halo.
                  BoxShadow(
                    color: kBrand.withValues(alpha: 0.5),
                    blurRadius: 48,
                    spreadRadius: -14,
                    offset: const Offset(0, 16),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          // Pending state is a shimmering label bone, never a spinner.
          child: loading
              ? const BusyButtonLabel(width: 110)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

/// The submit failure, shown as a tinted strip above the button so it cannot be
/// mistaken for one field's validation message.
class GlassErrorBanner extends StatelessWidget {
  const GlassErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kBrandErrorDeep.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          border: Border.all(color: kBrandErrorDeep.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: kBrandErrorDeep, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: kBrandErrorDeep,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single centred line: muted question, brand-coloured action.
class GlassFooterLink extends StatelessWidget {
  const GlassFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // A Wrap, not a Row: at a large text scale (or in a language with a longer
    // phrasing) the two halves need to be allowed onto separate lines rather
    // than overflow.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(color: kInk.withValues(alpha: 0.62), fontSize: 14.5),
        ),
        // A text button rather than a bare GestureDetector: this is the only
        // way off the screen, and it needs a real 48px tap target.
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: kBrandDeep,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
