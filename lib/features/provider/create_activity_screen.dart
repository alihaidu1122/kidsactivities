import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../categories/categories_providers.dart';
import '../profile/user_profile_providers.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  String _city = 'Tallinn';
  int _ageMin = 2;
  int _ageMax = 16;
  num? _priceAmount;
  String _priceType = 'per_session';
  String _address = '';
  String _locationName = '';
  String _scheduleDetails = '';
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 0) {
      if (!(_formKey.currentState?.validate() ?? false)) return false;
      if ((_category ?? '').trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _save({required bool asDraft}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final db = ref.read(firestoreProvider);
    if (user == null) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      final refDoc = db.collection('activities').doc();
      await refDoc.set({
        'activityId': refDoc.id,
        'providerUserId': user.uid,
        'providerBusinessName': null,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _category ?? '',
        'subCategory': null,
        'ageRangeMin': _ageMin,
        'ageRangeMax': _ageMax,
        'city': _city,
        'address': _address,
        'locationName': _locationName,
        'priceAmount': _priceAmount,
        'priceCurrency': 'EUR',
        'priceType': _priceType,
        'priceNotes': null,
        'scheduleType': 'weekly',
        'scheduleDetails': _scheduleDetails,
        'startDate': null,
        'endDate': null,
        'photos': <String>[],
        'videoUrl': null,
        'languages': <String>['Estonian', 'English', 'Russian'],
        'maxParticipants': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': !asDraft,
        'approvalStatus': 'pending',
        'rejectionReason': null,
        'viewCount': 0,
        'inquiryCount': 0,
      });
      if (!mounted) return;
      navigator.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Listing')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 1024;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ListView(
                    children: [
                      Text('Create New Listing', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        "Tell parents about the amazing experience you're offering.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      _StepperBar(step: _step),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_step == 0) ...[
                                  _GeneralInfoStep(
                                    titleCtrl: _titleCtrl,
                                    descCtrl: _descCtrl,
                                    category: _category,
                                    onCategory: (v) => setState(() => _category = v),
                                    city: _city,
                                    onCity: (v) => setState(() => _city = v),
                                    ageMin: _ageMin,
                                    ageMax: _ageMax,
                                    onAgeMin: (v) => setState(() => _ageMin = v),
                                    onAgeMax: (v) => setState(() => _ageMax = v),
                                  ),
                                ] else if (_step == 1) ...[
                                  _PricingStep(
                                    priceAmount: _priceAmount,
                                    priceType: _priceType,
                                    onPriceAmount: (v) => setState(() => _priceAmount = v),
                                    onPriceType: (v) => setState(() => _priceType = v),
                                  ),
                                ] else if (_step == 2) ...[
                                  _LocationStep(
                                    address: _address,
                                    locationName: _locationName,
                                    onAddress: (v) => setState(() => _address = v),
                                    onLocationName: (v) => setState(() => _locationName = v),
                                  ),
                                ] else ...[
                                  _MediaStep(
                                    scheduleDetails: _scheduleDetails,
                                    onScheduleDetails: (v) => setState(() => _scheduleDetails = v),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _saving ? null : () => _save(asDraft: true),
                                      child: const Text('Save as Draft'),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () async {
                                              if (!_validateStep()) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Please complete required fields.')),
                                                );
                                                return;
                                              }
                                              if (_step < 3) {
                                                setState(() => _step++);
                                                return;
                                              }
                                              await _save(asDraft: false);
                                            },
                                      icon: Icon(_step < 3 ? Icons.arrow_forward : Icons.check),
                                      label: Text(_saving
                                          ? 'Saving…'
                                          : _step < 3
                                              ? 'Next Step'
                                              : 'Publish'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSidebar) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const _TipCard(),
                        const SizedBox(height: 16),
                        _PreviewCard(
                          category: _category,
                          title: _titleCtrl.text,
                          scheduleDetails: _scheduleDetails,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => when(data: (v) => v, loading: () => null, error: (err, st) => null);
}

class _StepperBar extends StatelessWidget {
  const _StepperBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['General info', 'Pricing', 'Location', 'Media'];
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: List.generate(4, (i) {
            final active = i <= step;
            return Expanded(
              child: Row(
                children: [
                  _StepDot(index: i + 1, active: active, current: i == step),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (i != 3)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active, required this.current});
  final int index;
  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = active ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: current ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))] : null,
      ),
      alignment: Alignment.center,
      child: Text('$index', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class _GeneralInfoStep extends ConsumerWidget {
  const _GeneralInfoStep({
    required this.titleCtrl,
    required this.descCtrl,
    required this.category,
    required this.onCategory,
    required this.city,
    required this.onCity,
    required this.ageMin,
    required this.ageMax,
    required this.onAgeMin,
    required this.onAgeMax,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String? category;
  final ValueChanged<String> onCategory;
  final String city;
  final ValueChanged<String> onCity;
  final int ageMin;
  final int ageMax;
  final ValueChanged<int> onAgeMin;
  final ValueChanged<int> onAgeMax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(activeCategoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Activity Title',
            hintText: 'e.g., Saturday Morning Oil Painting for Kids',
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Title is required.' : null,
        ),
        const SizedBox(height: 8),
        Text(
          'Make it catchy! Titles between 40–60 characters perform best.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text('Primary Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        catsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Failed to load categories: $e'),
          data: (cats) {
            final show = cats.take(12).toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in show)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _CategoryChip(
                        emoji: c.icon ?? '⭐',
                        label: _shortLabel(c.name),
                        selected: category == c.name,
                        onTap: () => onCategory(c.name),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descCtrl,
          minLines: 5,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Detailed Description',
            hintText: 'Describe what children will learn, what to bring, materials included…',
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Description is required.' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: city,
          decoration: const InputDecoration(labelText: 'City'),
          items: const [
            DropdownMenuItem(value: 'Tallinn', child: Text('Tallinn')),
            DropdownMenuItem(value: 'Tartu', child: Text('Tartu')),
            DropdownMenuItem(value: 'Pärnu', child: Text('Pärnu')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (v) => onCity(v ?? 'Tallinn'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '$ageMin',
                decoration: const InputDecoration(labelText: 'Min age'),
                keyboardType: TextInputType.number,
                onChanged: (v) => onAgeMin(int.tryParse(v) ?? ageMin),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: '$ageMax',
                decoration: const InputDecoration(labelText: 'Max age'),
                keyboardType: TextInputType.number,
                onChanged: (v) => onAgeMax(int.tryParse(v) ?? ageMax),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected ? scheme.primary : scheme.outlineVariant;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHighest,
                border: Border.all(color: border, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.priceAmount,
    required this.priceType,
    required this.onPriceAmount,
    required this.onPriceType,
  });

  final num? priceAmount;
  final String priceType;
  final ValueChanged<num?> onPriceAmount;
  final ValueChanged<String> onPriceType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: priceAmount?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Price (EUR)'),
          keyboardType: TextInputType.number,
          onChanged: (v) => onPriceAmount(num.tryParse(v)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: priceType,
          decoration: const InputDecoration(labelText: 'Price type'),
          items: const [
            DropdownMenuItem(value: 'per_session', child: Text('Per session')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'term', child: Text('Term')),
            DropdownMenuItem(value: 'free', child: Text('Free')),
          ],
          onChanged: (v) => onPriceType(v ?? 'per_session'),
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.address,
    required this.locationName,
    required this.onAddress,
    required this.onLocationName,
  });

  final String address;
  final String locationName;
  final ValueChanged<String> onAddress;
  final ValueChanged<String> onLocationName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: locationName,
          decoration: const InputDecoration(labelText: 'Location name'),
          onChanged: onLocationName,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: address,
          decoration: const InputDecoration(labelText: 'Address'),
          onChanged: onAddress,
        ),
      ],
    );
  }
}

class _MediaStep extends StatelessWidget {
  const _MediaStep({
    required this.scheduleDetails,
    required this.onScheduleDetails,
  });

  final String scheduleDetails;
  final ValueChanged<String> onScheduleDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: scheduleDetails,
          decoration: const InputDecoration(labelText: 'Schedule details'),
          minLines: 3,
          maxLines: 5,
          onChanged: onScheduleDetails,
        ),
        const SizedBox(height: 12),
        Text(
          'Media upload (photos/video) will be added next.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.tertiaryContainer.withValues(alpha: 0.18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: scheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro-Tip', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Detailed descriptions and clear age ranges get more inquiries. Mention if materials are included!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.category,
    required this.title,
    required this.scheduleDetails,
  });

  final String? category;
  final String title;
  final String scheduleDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = (category ?? '').trim().isEmpty ? 'PREVIEW' : category!;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 160,
            color: scheme.surfaceContainerHighest,
            child: Stack(
              children: [
                const Center(child: Icon(Icons.photo, size: 48)),
                Positioned(
                  top: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text('PREVIEW'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(cat, style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title.trim().isEmpty ? 'New Listing Title…' : title.trim(),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scheduleDetails.trim().isEmpty ? 'Details pending' : scheduleDetails.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shortLabel(String name) {
  // For names like "🎨 Painting & Drawing" -> "Painting"
  final s = name.replaceAll(RegExp(r'^\S+\s+'), '');
  return s.split(RegExp(r'[&/,-]')).first.trim().split(' ').take(1).join();
}

