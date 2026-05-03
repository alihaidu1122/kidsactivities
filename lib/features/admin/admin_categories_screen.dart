import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
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
        final dash = context.dash;
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: DashboardTextStyles.body(dash)));
        }
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: dash.accentBlue));
        }
        final docs = snap.data!.docs;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Categories', style: DashboardTextStyles.pageTitle(context.dash)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 1100
                            ? 4
                            : c.maxWidth >= 720
                                ? 3
                                : c.maxWidth >= 480
                                    ? 2
                                    : 1;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final d = doc.data();
                            final name = (d['categoryName'] as String?) ?? '';
                            final icon = (d['icon'] as String?) ?? '🏷️';
                            final active = (d['isActive'] as bool?) ?? true;
                            final en = (d['categoryName'] as String?) ?? '';
                            final et = (d['categoryNameEt'] as String?) ?? '—';
                            return _CategoryDashCard(
                              emoji: icon,
                              name: name.isEmpty ? 'Category' : name,
                              badgeEn: en.isNotEmpty ? (en.length > 24 ? en.substring(0, 24) : en) : 'EN',
                              badgeEt: et,
                              active: active,
                              onToggle: (v) async {
                                await doc.reference.set(
                                  {'isActive': v, 'updatedAt': FieldValue.serverTimestamp()},
                                  SetOptions(merge: true),
                                );
                              },
                              onEdit: () {},
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                backgroundColor: context.dash.accentBlue,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _CreateCategoryScreen()),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryDashCard extends StatefulWidget {
  const _CategoryDashCard({
    required this.emoji,
    required this.name,
    required this.badgeEn,
    required this.badgeEt,
    required this.active,
    required this.onToggle,
    required this.onEdit,
  });

  final String emoji;
  final String name;
  final String badgeEn;
  final String badgeEt;
  final bool active;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  State<_CategoryDashCard> createState() => _CategoryDashCardState();
}

class _CategoryDashCardState extends State<_CategoryDashCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: d.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: d.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                if (_hover)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onEdit,
                    icon: Icon(Icons.edit_outlined, size: 18, color: d.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.name,
              style: DashboardTextStyles.cardTitle(d).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.bgSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badgeEn,
                      style: DashboardTextStyles.label(d).copyWith(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.bgSecondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ET: ${widget.badgeEt}',
                      style: DashboardTextStyles.label(d).copyWith(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text('Active', style: DashboardTextStyles.label(d)),
                const Spacer(),
                Switch(
                  value: widget.active,
                  onChanged: widget.onToggle,
                  activeTrackColor: d.accentBlue.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
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

