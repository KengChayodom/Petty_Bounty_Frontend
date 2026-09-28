import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../domain/auth_validators.dart';
import 'widgets/glass_auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // One per field after the first, so Enter / "next" walks the form in order
  // instead of dismissing the keyboard between every entry.
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ref
          .read(authServiceProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: _usernameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;

      // SRS-09: always confirm the sign-up succeeded.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful')));

      // SRS-10: with email confirmation OFF a session exists immediately and
      // the auth-stream router lands the user on Home Map. If confirmation is
      // required (no session) fall back to the login page.
      if (response.session == null) {
        context.pop();
      }
    } on AuthException catch (e) {
      // SRS-07: surface a clean "Email already exists" for the duplicate case.
      final alreadyRegistered = e.message.toLowerCase().contains(
        'already registered',
      );
      setState(
        () => _error = alreadyRegistered ? 'Email already exists' : e.message,
      );
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassAuthScaffold(
      formKey: _formKey,
      // Five fields: a full-height brandmark would push the first one off a
      // small screen before the user has typed anything.
      compact: true,
      onBack: _loading ? null : () => context.pop(),
      title: 'Create your account',
      subtitle: 'Join the hunt and help bring pets home.',
      footer: GlassFooterLink(
        question: 'Already have an account?',
        action: 'Sign in',
        onTap: _loading ? null : () => context.pop(),
      ),
      children: [
        GlassAuthField(
          label: 'Username',
          icon: Icons.person_outline,
          controller: _usernameController,
          textCapitalization: TextCapitalization.words,
          validator: AuthValidators.username,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        GlassAuthField(
          label: 'Email',
          icon: Icons.alternate_email,
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: AuthValidators.email,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
        GlassAuthField(
          label: 'Phone',
          icon: Icons.phone_outlined,
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          maxLength: 20, // hard cap at the UI (DB column is nullable)
          validator: AuthValidators.phone,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        GlassAuthField(
          label: 'Password',
          icon: Icons.lock_outline,
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          validator: AuthValidators.password,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        ),
        GlassAuthField(
          label: 'Confirm password',
          icon: Icons.lock_reset_outlined,
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) =>
              AuthValidators.confirmPassword(v, _passwordController.text),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_loading) _submit();
          },
        ),
        if (_error != null) GlassErrorBanner(_error!),
        const SizedBox(height: 4),
        GlassPrimaryButton(
          label: 'Register',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
