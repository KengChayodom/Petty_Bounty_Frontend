import 'package:flutter/material.dart';

import '../../../../core/ui/skeleton/skeleton.dart';

/// Shared visual shell + form controls for the Login / Register screens.
///
/// Presentation-only: these widgets hold NO auth logic. The screens keep their
/// controllers, validators, and submit handlers and just compose these pieces,
/// so the styling lives in one place and both screens stay pixel-identical.

/// Theme tokens for the auth screens (kept local to this feature).
const Color kAuthOrange = Color(0xFFEC8B4B);
const Color kAuthFieldFill = Color(0xFFE9E9E9);
const Color kAuthLinkRed = Color(0xFFE5392F);

/// Gradient background + centered logo, "Petty Bounty" wordmark, and a subtitle.
/// [children] are laid out (stretched) below the header — the form fields,
/// error text, primary button, and footer link.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.formKey,
    required this.subtitle,
    required this.children,
  });

  /// The owning screen's form key — wraps [children] so the screen's
  /// `validate()` reaches these fields.
  final GlobalKey<FormState> formKey;

  /// e.g. "Sign in to your account" / "Create your account".
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0A157), // saturated orange at the top
              Color(0xFFF8D2B2), // soft peach mid
              Colors.white, // fades to white at the bottom
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const _AuthLogo(),
                  const SizedBox(height: 18),
                  const _AuthWordmark(),
                  const SizedBox(height: 22),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
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

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pets, color: kAuthOrange, size: 52),
      ),
    );
  }
}

class _AuthWordmark extends StatelessWidget {
  const _AuthWordmark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Petty Bounty',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
    );
  }
}

/// A white bold label above a filled grey rounded text field — the repeated
/// "User name / Email / Phone / Password / ..." pattern from the mockups.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            autofillHints: autofillHints,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            decoration: const InputDecoration(
              filled: true,
              fillColor: kAuthFieldFill,
              counterText: '',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: kAuthOrange, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width pill button in the app orange, with an inline loading spinner.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
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
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAuthOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAuthOrange.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
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
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

/// Two-line centered footer: a black question + a red tappable action.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
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
    return Column(
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: kAuthLinkRed,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Centered error line shown above the primary button (kept from both screens).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kAuthLinkRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
