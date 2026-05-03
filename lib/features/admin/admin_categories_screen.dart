import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final q = db.collection('categories').orderBy('sortOrder');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;

        return Scaffold(
          body: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final name = (d['categoryName'] as String?) ?? '';
              final active = (d['isActive'] as bool?) ?? true;
              final sort = (d['sortOrder'] as num?)?.toInt() ?? 0;
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('sortOrder: $sort'),
                  trailing: Switch(
                    value: active,
                    onChanged: (v) async {
                      await docs[i].reference.set(
                        {
                          'isActive': v,
                          'updatedAt': FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _CreateCategoryScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _CreateCategoryScreen extends ConsumerStatefulWidget {
  const _CreateCategoryScreen();

  @override
  ConsumerState<_CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<_CreateCategoryScreen> {
  final _nameCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('New category')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sortCtrl,
            decoration: const InputDecoration(labelText: 'Sort order'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      final sort = int.tryParse(_sortCtrl.text.trim()) ?? 0;
                      final refDoc = db.collection('categories').doc();
                      await refDoc.set({
                        'categoryId': refDoc.id,
                        'categoryName': _nameCtrl.text.trim(),
                        'categoryNameEt': null,
                        'categoryNameRu': null,
                        'icon': null,
                        'isActive': true,
                        'sortOrder': sort,
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (!mounted) return;
                      navigator.pop();
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Saving…' : 'Create'),
          ),
        ],
      ),
    );
  }
}

