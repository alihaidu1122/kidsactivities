import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import '../inquiries/inquiry_providers.dart';
import '../inquiries/inquiry.dart';

final _providerInboxSelectedIdProvider =
    NotifierProvider<_SelectedInquiryIdController, String?>(_SelectedInquiryIdController.new);
final _providerInboxQueryProvider = NotifierProvider<_InboxQueryController, String>(_InboxQueryController.new);
final _providerInboxFilterProvider =
    NotifierProvider<_InboxFilterController, String>(_InboxFilterController.new); // all|new|read|responded|closed

class _SelectedInquiryIdController extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

class _InboxQueryController extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

class _InboxFilterController extends Notifier<String> {
  @override
  String build() => 'all';
  void set(String v) => state = v;
}

class ProviderInboxScreen extends ConsumerWidget {
  const ProviderInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(providerInboxProvider);
    final filter = ref.watch(_providerInboxFilterProvider);
    final query = ref.watch(_providerInboxQueryProvider).trim().toLowerCase();
    final selectedId = ref.watch(_providerInboxSelectedIdProvider);

    return inboxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load inbox.\n$e')),
      data: (items) {
        final filtered = items.where((it) {
          if (filter != 'all' && it.status != filter) return false;
          if (query.isEmpty) return true;
          return it.parentName.toLowerCase().contains(query) ||
              it.message.toLowerCase().contains(query);
        }).toList();

        final isWide = MediaQuery.of(context).size.width >= 1100;
        final active = selectedId == null
            ? (filtered.isNotEmpty ? filtered.first : null)
            : filtered.where((i) => i.id == selectedId).firstOrNull;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderBar(
                onSearch: (v) => ref.read(_providerInboxQueryProvider.notifier).set(v),
                filter: filter,
                onFilter: (v) => ref.read(_providerInboxFilterProvider.notifier).set(v),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          SizedBox(
                            width: 420,
                            child: _InboxList(
                              items: filtered,
                              selectedId: active?.id,
                              onSelect: (id) => ref.read(_providerInboxSelectedIdProvider.notifier).set(id),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DetailPane(active: active),
                          ),
                        ],
                      )
                    : _InboxList(
                        items: filtered,
                        selectedId: null,
                        onSelect: (id) async {
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => _InquiryDetailScreen(inquiryId: id)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onSearch,
    required this.filter,
    required this.onFilter,
  });

  final ValueChanged<String> onSearch;
  final String filter;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final segmented = SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'all', label: Text('All')),
        ButtonSegment(value: 'new', label: Text('New')),
        ButtonSegment(value: 'responded', label: Text('Responded')),
        ButtonSegment(value: 'closed', label: Text('Closed')),
      ],
      selected: {filter},
      onSelectionChanged: (s) => onFilter(s.first),
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 720;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inquiry Inbox', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Manage questions and booking requests from parents.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final searchField = TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search inquiries',
              ),
              onChanged: onSearch,
            );

            if (wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 16),
                      SizedBox(width: 280, child: searchField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: segmented,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                searchField,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: segmented,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InquiryDetailScreen extends ConsumerStatefulWidget {
  const _InquiryDetailScreen({required this.inquiryId});
  final String inquiryId;

  @override
  ConsumerState<_InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends ConsumerState<_InquiryDetailScreen> {
  final _respCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _respCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(firestoreProvider);
    final docRef = db.doc('inquiries/${widget.inquiryId}');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!.data() ?? const <String, dynamic>{};

        final status = (data['status'] as String?) ?? 'new';
        _respCtrl.text = (_respCtrl.text.isEmpty ? (data['providerResponse'] as String? ?? '') : _respCtrl.text);

        return Scaffold(
          appBar: AppBar(title: const Text('Inquiry')),
          body: _DetailBody(
            data: data,
            status: status,
            respCtrl: _respCtrl,
            saving: _saving,
            onResponded: () async {
              setState(() => _saving = true);
              try {
                await docRef.set(
                  {
                    'providerResponse': _respCtrl.text.trim(),
                    'status': 'responded',
                    'respondedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            onClosed: () async {
              setState(() => _saving = true);
              try {
                await docRef.set(
                  {'status': 'closed'},
                  SetOptions(merge: true),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
        );
      },
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList({
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Inquiry> items;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const Center(child: Text('No inquiries found.'));
    final db = ref.watch(firestoreProvider);

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final it = items[i];
        final selected = selectedId == it.id;
        return _InboxTile(
          inquiry: it,
          selected: selected,
          onTap: () async {
            await db.doc('inquiries/${it.id}').set(
              {
                'status': it.status == 'new' ? 'read' : it.status,
                'readAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
            onSelect(it.id);
          },
        );
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.inquiry, required this.selected, required this.onTap});
  final Inquiry inquiry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surface;
    final border = selected ? scheme.primary.withValues(alpha: 0.35) : scheme.outlineVariant;
    final tag = switch (inquiry.status) {
      'new' => ('New Inquiry', scheme.tertiaryContainer, scheme.onTertiaryContainer),
      'read' => ('Read', scheme.secondaryContainer, scheme.onSecondaryContainer),
      'responded' => ('Responded', scheme.secondaryContainer, scheme.onSecondaryContainer),
      'closed' => ('Closed', scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (inquiry.status, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    final initials = (inquiry.parentName.trim().isEmpty ? '?' : inquiry.parentName.trim())
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: selected
                ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(initials, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inquiry.parentName.isEmpty ? '(No name)' : inquiry.parentName,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _relativeTime(inquiry.createdAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Tag(text: tag.$1, bg: tag.$2, fg: tag.$3),
                          if (inquiry.childAge != null) _Meta(text: 'Child: ${inquiry.childAge} yrs'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inquiry.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({required this.active});
  final Inquiry? active;

  @override
  Widget build(BuildContext context) {
    if (active == null) {
      return const Center(child: Text('Select an inquiry to preview.'));
    }
    return Card(
      elevation: 0,
      child: _InquiryDetailScreen(inquiryId: active!.id),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.status,
    required this.respCtrl,
    required this.saving,
    required this.onResponded,
    required this.onClosed,
  });

  final Map<String, dynamic> data;
  final String status;
  final TextEditingController respCtrl;
  final bool saving;
  final Future<void> Function() onResponded;
  final Future<void> Function() onClosed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = (data['parentName'] as String?) ?? '';
    final email = (data['parentEmail'] as String?) ?? '';
    final phone = (data['parentPhone'] as String?) ?? '';
    final message = (data['message'] as String?) ?? '';
    final activityId = (data['activityId'] as String?) ?? '';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                  style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? '(No name)' : name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Active Inquiry • $activityId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Call',
                onPressed: phone.isEmpty ? null : () {},
                icon: const Icon(Icons.call_outlined),
              ),
              IconButton(
                tooltip: 'More',
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('Today'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: _Bubble(
                  text: message,
                  isMe: false,
                ),
              ),
              const SizedBox(height: 12),
              if (respCtrl.text.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: _Bubble(text: respCtrl.text.trim(), isMe: true),
                ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.secondary.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: scheme.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preferred contact: ${(data['preferredContactMethod'] as String?) ?? 'either'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Contact', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text('Email: $email'),
              Text('Phone: $phone'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickReply(
                      text: 'Yes, we have space!',
                      onTap: () => respCtrl.text = 'Yes, we have space!',
                    ),
                    const SizedBox(width: 8),
                    _QuickReply(
                      text: 'Tell me more about the age?',
                      onTap: () => respCtrl.text = 'Could you share the child’s age and any notes?',
                    ),
                    const SizedBox(width: 8),
                    _QuickReply(
                      text: 'Workshop is full',
                      onTap: () => respCtrl.text = 'Unfortunately this session is full. Would another day work?',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: respCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Type your response…',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: saving || status == 'closed' ? null : onClosed,
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving ? null : onResponded,
                      icon: const Icon(Icons.send),
                      label: Text(saving ? 'Sending…' : 'Send & mark responded'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isMe});
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMe ? scheme.primary : scheme.surface;
    final fg = isMe ? scheme.onPrimary : scheme.onSurface;
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
    );
  }
}

class _QuickReply extends StatelessWidget {
  const _QuickReply({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

