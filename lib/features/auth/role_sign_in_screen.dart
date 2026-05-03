import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import 'widgets/auth_brand_mark.dart';

/// Optional compile-time gate for the admin sign-in screen.
/// Build with: `--dart-define=ADMIN_PORTAL_CODE=your-secret`
const String _kAdminPortalCode = String.fromEnvironment('ADMIN_PORTAL_CODE', defaultValue: '');

enum AuthPortalRole { parent, provider, admin }

class RoleSignInScreen extends ConsumerStatefulWidget {
  const RoleSignInScreen({super.key, required this.role});

  final AuthPortalRole role;

  @override
  ConsumerState<RoleSignInScreen> createState() => _RoleSignInScreenState();
}

class _RoleSignInScreenState extends ConsumerState<RoleSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _adminGateOtherCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _adminGateOtherCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.role) {
        AuthPortalRole.parent => 'Parent sign in',
        AuthPortalRole.provider => 'Provider sign in',
        AuthPortalRole.admin => 'Admin sign in',
      };

  String get _subtitle => switch (widget.role) {
        AuthPortalRole.parent => 'Use the email and password for your parent account.',
        AuthPortalRole.provider => 'Use the email and password issued for your provider account.',
        AuthPortalRole.admin => 'Use your admin credentials (strong password required).',
      };

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.role == AuthPortalRole.admin && _kAdminPortalCode.isNotEmpty) {
      if (_adminGateOtherCtrl.text.trim() != _kAdminPortalCode) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Invalid admin access code.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final auth = ref.read(authControllerProvider);
      await auth.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      if (!mounted) return;
      context.go('/');
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Wrong email or password.';
    if (s.contains('user-not-found')) return 'No account found for that email.';
    if (s.contains('invalid-email')) return 'Please enter a valid email.';
    if (s.contains('network-request-failed')) return 'Network error. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _loading ? null : () => context.go('/welcome'),
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: AuthBrandMark(compact: true)),
                    const SizedBox(height: 16),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(_subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (widget.role == AuthPortalRole.admin && _kAdminPortalCode.isNotEmpty) ...[
                      TextFormField(
                        controller: _adminGateOtherCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Admin access code',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return 'Required.';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Email is required.';
                        if (!s.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_passwordVisible,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Password is required.';
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_loading) _submit();
                      },
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Signing in…' : 'Sign in'),
                    ),
                    if (widget.role == AuthPortalRole.parent) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => context.go('/join'),
                        child: const Text('Create parent account'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final email = _emailCtrl.text.trim();
                              if (email.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Enter your email first.')),
                                );
                                return;
                              }
                              try {
                                await ref.read(authControllerProvider).sendPasswordResetEmail(email: email);
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Password reset email sent.')),
                                );
                              } on Exception catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
                              }
                            },
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
