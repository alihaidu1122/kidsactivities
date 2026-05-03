import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import '../activities/activity.dart';

class AdminActivityModerationScreen extends ConsumerWidget {
  const AdminActivityModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final q = db
        .collection('activities')
        .where('approvalStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!.docs.map(Activity.fromDoc).toList();
        if (items.isEmpty) {
          return const Center(child: Text('No pending activities.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _PendingCard(activity: items[i]),
        );
      },
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.title.isEmpty ? '(Untitled)' : activity.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${activity.city} • ${activity.category} • ${activity.ageRangeMin}-${activity.ageRangeMax}'),
            const SizedBox(height: 8),
            Text(
              activity.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await db.doc('activities/${activity.id}').set(
                      {
                        'approvalStatus': 'approved',
                        'rejectionReason': null,
                        'approvedAt': FieldValue.serverTimestamp(),
                        'approvedBy': 'admin', // for audit; replace with uid later
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final reason = await showDialog<String>(
                      context: context,
                      builder: (context) => const _RejectDialog(),
                    );
                    if (reason == null) return;
                    await db.doc('activities/${activity.id}').set(
                      {
                        'approvalStatus': 'rejected',
                        'rejectionReason': reason.trim().isEmpty ? 'Rejected' : reason.trim(),
                        'rejectedAt': FieldValue.serverTimestamp(),
                        'rejectedBy': 'admin',
                        'updatedAt': FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject activity'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Reject')),
      ],
    );
  }
}

