import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            displayName: _displayNameController.text.trim(),
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
    return AuthScaffold(
      formKey: _formKey,
      subtitle: 'Create your account',
      children: [
        AuthField(
          label: 'Username',
          controller: _displayNameController,
          textCapitalization: TextCapitalization.words,
          validator: AuthValidators.username,
        ),
        AuthField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: AuthValidators.email,
        ),
        AuthField(
          label: 'Phone',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 20, // hard cap at the UI (DB column is nullable)
          validator: AuthValidators.phone,
        ),
        AuthField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          validator: AuthValidators.password,
        ),
        AuthField(
          label: 'Confirm password',
          controller: _confirmPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          validator: (v) =>
              AuthValidators.confirmPassword(v, _passwordController.text),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          AuthErrorText(_error!),
        ],
        const SizedBox(height: 6),
        AuthPrimaryButton(
          label: 'Register',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        AuthFooterLink(
          question: 'You already have account ?',
          action: 'Sign in',
          onTap: _loading ? null : () => context.pop(),
        ),
      ],
    );
  }
}
