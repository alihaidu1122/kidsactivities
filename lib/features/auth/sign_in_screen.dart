import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();
  bool _signUp = false;
  bool _passwordVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await fn();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Wrong email or password.';
    if (s.contains('user-not-found')) return 'No account found for that email.';
    if (s.contains('email-already-in-use')) return 'That email is already in use.';
    if (s.contains('invalid-email')) return 'Please enter a valid email.';
    if (s.contains('weak-password')) return 'Password is too weak (min 8 characters).';
    if (s.contains('network-request-failed')) return 'Network error. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AutofillGroup(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 8),
                      const _LogoHeader(),
                      const SizedBox(height: 20),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Sign in')),
                          ButtonSegment(value: true, label: Text('Create account')),
                        ],
                        selected: {_signUp},
                        onSelectionChanged: _loading
                            ? null
                            : (set) {
                                final next = set.first;
                                if (next) {
                                  context.go('/join');
                                  setState(() => _signUp = false);
                                  return;
                                }
                                setState(() => _signUp = false);
                              },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _signUp ? 'Welcome' : 'Welcome back',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _signUp
                                      ? 'Create an account to browse and contact providers.'
                                      : 'Sign in to continue.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
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
                                      tooltip: _passwordVisible ? 'Hide password' : 'Show password',
                                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                      icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                                    ),
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '');
                                    if (s.isEmpty) return 'Password is required.';
                                    if (_signUp && s.length < 8) return 'Minimum 8 characters.';
                                    return null;
                                  },
                                  textInputAction: _signUp ? TextInputAction.next : TextInputAction.done,
                                ),
                                if (_signUp) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _password2Ctrl,
                                    obscureText: true,
                                    autofillHints: const [AutofillHints.password],
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    validator: (v) {
                                      if ((v ?? '').isEmpty) return 'Please confirm password.';
                                      if (v != _passwordCtrl.text) return 'Passwords do not match.';
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _loading
                                      ? null
                                      : () => _run(() async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            if (!(_formKey.currentState?.validate() ?? false)) return;
                                            final email = _emailCtrl.text.trim();
                                            final pw = _passwordCtrl.text;
                                            if (_signUp) {
                                              await auth.signUp(email: email, password: pw);
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Account created. You can sign in now.'),
                                                ),
                                              );
                                            } else {
                                              await auth.signIn(email: email, password: pw);
                                            }
                                          }),
                                  child: Text(_loading
                                      ? (_signUp ? 'Creating…' : 'Signing in…')
                                      : (_signUp ? 'Create account' : 'Sign in')),
                                ),
                                const SizedBox(height: 8),
                                if (!_signUp)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _run(() async {
                                                final messenger = ScaffoldMessenger.of(context);
                                                final email = _emailCtrl.text.trim();
                                                if (email.isEmpty) throw Exception('Enter your email first.');
                                                await auth.sendPasswordResetEmail(email: email);
                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  const SnackBar(content: Text('Password reset email sent.')),
                                                );
                                              }),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  'By continuing, you agree to our Terms and Privacy Policy.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Logo and branding are placeholders — you can replace them anytime.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(Icons.directions_run, size: 34, color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kids Activities Estonia',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Find and contact trusted activities for kids in Estonia.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

