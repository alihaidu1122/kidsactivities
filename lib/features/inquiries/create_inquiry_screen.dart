import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../profile/user_profile_providers.dart';
import '../activities/activity.dart';

class CreateInquiryScreen extends ConsumerStatefulWidget {
  const CreateInquiryScreen({super.key, required this.activity});
  final Activity activity;

  @override
  ConsumerState<CreateInquiryScreen> createState() => _CreateInquiryScreenState();
}

class _CreateInquiryScreenState extends ConsumerState<CreateInquiryScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _method = 'either';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final db = ref.watch(firestoreProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Contact provider')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.activity.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your name')),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Preferred contact method'),
            items: const [
              DropdownMenuItem(value: 'either', child: Text('Either')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'phone', child: Text('Phone')),
            ],
            onChanged: _saving ? null : (v) => setState(() => _method = v ?? 'either'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    setState(() => _saving = true);
                    try {
                      final refDoc = db.collection('inquiries').doc();
                      await refDoc.set({
                        'inquiryId': refDoc.id,
                        'activityId': widget.activity.id,
                        'parentUserId': user.uid,
                        'providerUserId': widget.activity.providerUserId,
                        'parentName': _nameCtrl.text.trim(),
                        'parentEmail': _emailCtrl.text.trim(),
                        'parentPhone': _phoneCtrl.text.trim(),
                        'childAge': null,
                        'message': _msgCtrl.text.trim(),
                        'preferredContactMethod': _method,
                        'status': 'new',
                        'createdAt': FieldValue.serverTimestamp(),
                        'readAt': null,
                        'respondedAt': null,
                        'providerResponse': null,
                        'providerContactInfo': null,
                      });
                      if (!mounted) return;
                      navigator.pop(true);
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Sending…' : 'Send inquiry'),
          ),
        ],
      ),
    );
  }
}

extension _AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => when(data: (v) => v, loading: () => null, error: (err, st) => null);
}

