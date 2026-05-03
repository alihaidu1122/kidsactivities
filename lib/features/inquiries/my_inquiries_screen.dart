import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inquiry_providers.dart';

class MyInquiriesScreen extends ConsumerWidget {
  const MyInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(mySentInquiriesProvider);
    return inquiriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load inquiries.\n$e')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No inquiries yet.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final it = items[i];
            return Card(
              child: ListTile(
                title: Text(it.message.isEmpty ? '(No message)' : it.message),
                subtitle: Text('Status: ${it.status}'),
              ),
            );
          },
        );
      },
    );
  }
}

