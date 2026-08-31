import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../routing/app_router.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Register this device against the account that just signed in. Home
      // also does this, but only after the location-permission flow settles —
      // a user who never reaches Home, or whose location flow stalls, would
      // otherwise never get a `device_tokens` row and could never be pushed.
      // Deliberately not awaited: the router redirect should not wait on a
      // network round-trip, and syncToken swallows its own failures.
      unawaited(FcmService.instance.syncToken());

      // The router's redirect (driven by the auth stream) takes us home.
    } on AuthException catch (_) {
      // SRS-12: fixed message — never reveal whether the email exists.
      setState(() => _error = 'Invalid email or password');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      formKey: _formKey,
      subtitle: 'Sign in to your account',
      children: [
        // Labelled "User name" to match the design; still bound to the email
        // controller because Supabase auth logs in by email (the user types
        // their email here), so SRS-03/04 email validation is preserved.
        AuthField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: AuthValidators.email,
        ),
        AuthField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          validator: AuthValidators.loginPassword,
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          AuthErrorText(_error!),
        ],
        const SizedBox(height: 6),
        AuthPrimaryButton(
          label: 'Sign in',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          question: "Don't you have account ?",
          action: 'Register here',
          onTap: _loading ? null : () => context.push(AppRoutes.register),
        ),
      ],
    );
  }
}
