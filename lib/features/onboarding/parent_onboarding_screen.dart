import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../categories/categories_providers.dart';
import '../profile/user_profile_providers.dart';

class ParentOnboardingScreen extends ConsumerStatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  ConsumerState<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends ConsumerState<ParentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _city = 'Tallinn';
  String _language = 'et';

  final List<_ChildDraft> _children = [
    _ChildDraft(name: '', age: null, interests: <String>{}),
  ];

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authControllerProvider);
      await auth.signUp(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);

      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Not signed in after signup.');

      final fullName = _nameCtrl.text.trim();
      final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      final firstName = parts.isEmpty ? null : parts.first;
      final lastName = parts.length <= 1 ? null : parts.sublist(1).join(' ');

      final db = ref.read(firestoreProvider);
      await db.doc('users/$uid').set(
        {
          'parentProfile': {
            'firstName': firstName,
            'lastName': lastName,
            'city': _city,
            'preferredLanguage': _language,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final kids = _children
          .map((c) => c.cleaned())
          .where((c) => c != null)
          .cast<_ChildDraft>()
          .toList();

      for (final c in kids) {
        final refDoc = db.collection('users').doc(uid).collection('children').doc();
        await refDoc.set({
          'childId': refDoc.id,
          'parentUserId': uid,
          'firstName': c.name.trim(),
          'age': c.age,
          'dateOfBirth': null,
          'interests': c.interests.toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use')) return 'That email is already in use.';
    if (s.contains('invalid-email')) return 'Please enter a valid email.';
    if (s.contains('weak-password')) return 'Password is too weak (min 8 characters).';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: scheme.primary),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.18,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1503455637927-730bce8583c0?auto=format&fit=crop&w=1600&q=80',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to the family, Estonia!',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Join the community of parents finding the best activities for their kids in Tallinn, Tartu, and Pärnu.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: const [
                                  Expanded(child: _GlassFeature(icon: Icons.verified, label: 'Verified Providers')),
                                  SizedBox(width: 12),
                                  Expanded(child: _GlassFeature(icon: Icons.favorite, label: 'Curated Selection')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Container(
                color: scheme.surface,
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 20, vertical: 28),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      children: [
                        if (!isWide) ...[
                          Text('KiddoMarket', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Create your parent account', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 20),
                        ],
                        const _ProgressBar(activeSegments: 2, total: 4),
                        const SizedBox(height: 22),
                        Text('Step 1: Parent Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                          "Let's start with the basics to personalize your experience.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email Address', hintText: 'hello@example.ee'),
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return 'Email is required.';
                                  if (!s.contains('@')) return 'Enter a valid email.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password', hintText: '••••••••'),
                                validator: (v) {
                                  final s = v ?? '';
                                  if (s.isEmpty) return 'Password is required.';
                                  if (s.length < 8) return 'Minimum 8 characters.';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameCtrl,
                                      decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Anna Kask'),
                                      validator: (v) => (v ?? '').trim().isEmpty ? 'Name is required.' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _city,
                                      decoration: const InputDecoration(labelText: 'City'),
                                      items: const [
                                        DropdownMenuItem(value: 'Tallinn', child: Text('Tallinn')),
                                        DropdownMenuItem(value: 'Tartu', child: Text('Tartu')),
                                        DropdownMenuItem(value: 'Pärnu', child: Text('Pärnu')),
                                      ],
                                      onChanged: _loading ? null : (v) => setState(() => _city = v ?? 'Tallinn'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Preferred Language', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: _LangButton(code: 'et', label: 'ET', selected: _language == 'et', onTap: _loading ? null : () => setState(() => _language = 'et'))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _LangButton(code: 'en', label: 'EN', selected: _language == 'en', onTap: _loading ? null : () => setState(() => _language = 'en'))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _LangButton(code: 'ru', label: 'RU', selected: _language == 'ru', onTap: _loading ? null : () => setState(() => _language = 'ru'))),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Divider(height: 1, color: scheme.outlineVariant),
                              const SizedBox(height: 18),
                              _ChildrenCard(
                                children: _children,
                                onAdd: _loading
                                    ? null
                                    : () => setState(() => _children.add(_ChildDraft(name: '', age: null, interests: <String>{}))),
                                onRemove: _loading || _children.length <= 1
                                    ? null
                                    : (i) => setState(() => _children.removeAt(i)),
                                onChanged: _loading
                                    ? null
                                    : (i, c) => setState(() => _children[i] = c),
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                child: Text(_loading ? 'Creating…' : 'Continue to Discovery'),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Already have an account? ', style: Theme.of(context).textTheme.bodySmall),
                                  TextButton(
                                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                                    child: const Text('Log in here'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: 0.6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('KiddoMarket OÜ © 2024'),
                              Row(children: [Text('Privacy'), SizedBox(width: 16), Text('Terms')]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassFeature extends StatelessWidget {
  const _GlassFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onPrimary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onPrimary))),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.activeSegments, required this.total});
  final int activeSegments;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final active = i < activeSegments;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.code, required this.label, required this.selected, required this.onTap});
  final String code;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: selected ? scheme.secondary : scheme.outlineVariant, width: 2),
        backgroundColor: selected ? scheme.secondary.withValues(alpha: 0.06) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(46),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            Icon(Icons.check_circle, size: 18, color: scheme.secondary),
            const SizedBox(width: 8),
          ],
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? scheme.secondary : scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ChildrenCard extends ConsumerWidget {
  const _ChildrenCard({
    required this.children,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_ChildDraft> children;
  final VoidCallback? onAdd;
  final void Function(int index)? onRemove;
  final void Function(int index, _ChildDraft child)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final catsAsync = ref.watch(activeCategoriesProvider);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Add Children', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add another')),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < children.length; i++) ...[
              _ChildEditor(
                index: i,
                child: children[i],
                canRemove: children.length > 1,
                onRemove: onRemove == null ? null : () => onRemove!(i),
                categoriesAsync: catsAsync,
                onChanged: onChanged == null ? null : (c) => onChanged!(i, c),
              ),
              if (i != children.length - 1) Divider(height: 26, color: scheme.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChildEditor extends StatelessWidget {
  const _ChildEditor({
    required this.index,
    required this.child,
    required this.canRemove,
    required this.onRemove,
    required this.categoriesAsync,
    required this.onChanged,
  });

  final int index;
  final _ChildDraft child;
  final bool canRemove;
  final VoidCallback? onRemove;
  final AsyncValue<List<CategoryItem>> categoriesAsync;
  final ValueChanged<_ChildDraft>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Child ${index + 1}', style: Theme.of(context).textTheme.labelLarge)),
            if (canRemove) IconButton(onPressed: onRemove, tooltip: 'Remove child', icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: child.name,
                decoration: const InputDecoration(labelText: "Child's Name", hintText: 'Leenu'),
                onChanged: (v) => onChanged?.call(child.copyWith(name: v)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: child.age?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Age', hintText: '5'),
                keyboardType: TextInputType.number,
                onChanged: (v) => onChanged?.call(child.copyWith(age: int.tryParse(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Interests', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in child.interests)
              InputChip(
                label: Text(t),
                onDeleted: onChanged == null ? null : () => onChanged!(child.removeInterest(t)),
              ),
            ActionChip(
              label: const Text('+ Tag'),
              onPressed: onChanged == null
                  ? null
                  : () async {
                      final tag = await _pickInterest(context, categoriesAsync);
                      if (tag == null) return;
                      onChanged!(child.addInterest(tag));
                    },
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> _pickInterest(BuildContext context, AsyncValue<List<CategoryItem>> catsAsync) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: catsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load categories: $e'),
            ),
            data: (cats) {
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Pick an interest', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  for (final c in cats)
                    ListTile(
                      leading: Text(c.icon ?? '⭐', style: const TextStyle(fontSize: 20)),
                      title: Text(c.name),
                      onTap: () => Navigator.of(context).pop(c.name),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ChildDraft {
  _ChildDraft({required this.name, required this.age, required Set<String> interests}) : interests = {...interests};
  final String name;
  final int? age;
  final Set<String> interests;

  _ChildDraft copyWith({String? name, int? age, Set<String>? interests}) {
    return _ChildDraft(name: name ?? this.name, age: age ?? this.age, interests: interests ?? this.interests);
  }

  _ChildDraft addInterest(String t) => copyWith(interests: {...interests, t});
  _ChildDraft removeInterest(String t) => copyWith(interests: {...interests}..remove(t));

  _ChildDraft? cleaned() {
    final n = name.trim();
    if (n.isEmpty && age == null && interests.isEmpty) return null;
    if (n.isEmpty) return null;
    if (age == null) return null;
    return this;
  }
}

