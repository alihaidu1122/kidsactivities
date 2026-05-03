import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_providers.dart';
import 'activity.dart';
import 'activity_details_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesFeedProvider);
    final filters = ref.watch(activityFiltersProvider);
    final filtersCtrl = ref.read(activityFiltersProvider.notifier);

    return Column(
      children: [
        _FiltersBar(filters: filters, ctrl: filtersCtrl),
        Expanded(
          child: activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Failed to load activities.\n$e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No activities found.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ActivityCard(activity: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.filters, required this.ctrl});
  final ActivityFilters filters;
  final ActivityFiltersController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: filters.city,
                decoration: const InputDecoration(labelText: 'City'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Any')),
                  DropdownMenuItem(value: 'Tallinn', child: Text('Tallinn')),
                  DropdownMenuItem(value: 'Tartu', child: Text('Tartu')),
                  DropdownMenuItem(value: 'Pärnu', child: Text('Pärnu')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => ctrl.setCity(v),
              ),
            ),
            SizedBox(
              width: 240,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Category (exact for now)',
                  hintText: 'e.g. 🏊 Swimming',
                ),
                onSubmitted: (v) => ctrl.setCategory(v.trim().isEmpty ? null : v.trim()),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                decoration: const InputDecoration(labelText: 'Min age'),
                keyboardType: TextInputType.number,
                onSubmitted: (v) {
                  final n = int.tryParse(v.trim());
                  ctrl.setMinAge(n);
                },
              ),
            ),
            TextButton(
              onPressed: () => ctrl.clear(),
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activity: activity)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title.isEmpty ? '(Untitled)' : activity.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(text: activity.city),
                  _Chip(text: activity.category),
                  _Chip(text: '${activity.ageRangeMin}-${activity.ageRangeMax} yrs'),
                  if (activity.priceAmount != null) _Chip(text: '€${activity.priceAmount}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.providerBusinessName ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

