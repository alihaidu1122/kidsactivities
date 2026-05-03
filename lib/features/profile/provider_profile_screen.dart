import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/dashboard_tokens.dart';
import '../auth/auth_providers.dart';
import 'profile_avatar_circle.dart';
import 'profile_feedback.dart';
import 'profile_field_styles.dart';
import 'profile_section_card.dart';
import 'user_profile_providers.dart';

class ProviderProfileCounts {
  const ProviderProfileCounts({required this.listings, required this.inquiries});

  final int listings;
  final int inquiries;
}

final _providerProfileCountsProvider = StreamProvider<ProviderProfileCounts>((ref) {
  final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
  if (user == null) return const Stream.empty();
  final db = ref.watch(firestoreProvider);
  final uid = user.uid;

  return Stream.multi((controller) {
    var listingsN = 0;
    var inquiriesN = 0;

    void emit() {
      if (controller.isClosed) return;
      controller.add(ProviderProfileCounts(listings: listingsN, inquiries: inquiriesN));
    }

    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    subs.add(
      db.collection('activities').where('providerUserId', isEqualTo: uid).snapshots().listen((s) {
        listingsN = s.docs.length;
        emit();
      }),
    );
    subs.add(
      db.collection('inquiries').where('providerUserId', isEqualTo: uid).snapshots().listen((s) {
        inquiriesN = s.docs.length;
        emit();
      }),
    );

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
  });
});

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bizNameCtrl = TextEditingController();
  final _bizBioCtrl = TextEditingController();
  final _bizEmailCtrl = TextEditingController();
  final _bizPhoneCtrl = TextEditingController();

  bool _seeded = false;
  bool _uploadingPhoto = false;
  bool _accountDirty = false;
  bool _businessDirty = false;
  String? _photoUrl;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizBioCtrl.dispose();
    _bizEmailCtrl.dispose();
    _bizPhoneCtrl.dispose();
    super.dispose();
  }

  void _seed(DocumentSnapshot<Map<String, dynamic>>? snap) {
    if (snap == null || !snap.exists) return;
    final data = snap.data() ?? {};
    _photoUrl = data['photoUrl'] as String?;
    _displayNameCtrl.text = (data['displayName'] as String?)?.trim() ?? '';
    _phoneCtrl.text = (data['phone'] as String?) ?? '';
    final pr = data['providerProfile'] as Map<String, dynamic>?;
    _bizNameCtrl.text = (pr?['businessName'] as String?) ?? '';
    _bizBioCtrl.text = (pr?['bio'] as String?) ?? '';
    _bizEmailCtrl.text = (pr?['publicEmail'] as String?) ?? '';
    _bizPhoneCtrl.text = (pr?['publicPhone'] as String?) ?? '';
  }

  Future<void> _pickPhoto(User user) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (image == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final storageRef = FirebaseStorage.instance.ref('profile_photos/${user.uid}.jpg');
      final meta = SettableMetadata(contentType: 'image/jpeg');
      if (kIsWeb) {
        await storageRef.putData(await image.readAsBytes(), meta);
      } else {
        await storageRef.putFile(File(image.path), meta);
      }
      final url = await storageRef.getDownloadURL();
      await ref.read(firestoreProvider).doc('users/${user.uid}').set({'photoUrl': url}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
      showProfileSuccessSnackBar(context, 'Profile photo updated!');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      showProfileErrorSnackBar(context, 'Failed to upload photo.');
    }
  }

  Future<void> _saveAccount(User user) async {
    final db = ref.read(firestoreProvider);
    try {
      final display = _displayNameCtrl.text.trim();
      if (display.isNotEmpty) await user.updateDisplayName(display);
      await db.doc('users/${user.uid}').set({
        'displayName': display,
        'phone': _phoneCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _accountDirty = false);
      showProfileSuccessSnackBar(context, 'Account saved.');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, '$e');
    }
  }

  Future<void> _saveBusiness(User user) async {
    final db = ref.read(firestoreProvider);
    try {
      await db.doc('users/${user.uid}').set({
        'updatedAt': FieldValue.serverTimestamp(),
        'providerProfile': {
          'businessName': _bizNameCtrl.text.trim().isEmpty ? null : _bizNameCtrl.text.trim(),
          'bio': _bizBioCtrl.text.trim().isEmpty ? null : _bizBioCtrl.text.trim(),
          'publicEmail': _bizEmailCtrl.text.trim().isEmpty ? null : _bizEmailCtrl.text.trim(),
          'publicPhone': _bizPhoneCtrl.text.trim().isEmpty ? null : _bizPhoneCtrl.text.trim(),
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _businessDirty = false);
      showProfileSuccessSnackBar(context, 'Business profile saved.');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    final docAsync = ref.watch(userDocProvider);
    final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
    final countsAsync = ref.watch(_providerProfileCountsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Material(
      color: d.bgPrimary,
      child: docAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: d.accentBlue)),
        error: (e, _) => Center(child: Text('$e', style: TextStyle(color: d.textMuted))),
        data: (snap) {
          if (!_seeded && snap != null && snap.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _seed(snap);
              setState(() => _seeded = true);
            });
          }

          final email = user?.email ?? '—';
          final counts = countsAsync.maybeWhen(data: (c) => c, orElse: () => const ProviderProfileCounts(listings: 0, inquiries: 0));

          final left = _ProviderSummaryCard(
            d: d,
            user: user,
            email: email,
            photoUrl: _photoUrl,
            uploading: _uploadingPhoto,
            counts: counts,
            onPhoto: user == null ? null : () => _pickPhoto(user),
          );

          final sections = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileSectionCard(
                d: d,
                icon: '👤',
                iconBg: d.accentBlueBg,
                title: 'Account',
                showSave: _accountDirty,
                onSave: user == null ? null : () => _saveAccount(user),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _displayNameCtrl,
                            style: dashProfileInputTextStyle(d),
                            decoration: dashProfileInputDecoration(d, 'DISPLAY NAME'),
                            onChanged: (_) => setState(() => _accountDirty = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: dashProfileInputTextStyle(d),
                            decoration: dashProfileInputDecoration(d, 'PHONE'),
                            onChanged: (_) => setState(() => _accountDirty = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('EMAIL', style: dashProfileLabelStyle(d)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: d.bgPrimary,
                        border: Border.all(color: d.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(email, style: GoogleFonts.dmSans(fontSize: 12, color: d.textMuted)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email cannot be changed from the app.',
                      style: GoogleFonts.dmSans(fontSize: 10, color: d.textFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ProfileSectionCard(
                d: d,
                icon: '🏢',
                iconBg: d.metricGreenBg,
                title: 'Business',
                showSave: _businessDirty,
                onSave: user == null ? null : () => _saveBusiness(user),
                child: Column(
                  children: [
                    TextField(
                      controller: _bizNameCtrl,
                      style: dashProfileInputTextStyle(d),
                      decoration: dashProfileInputDecoration(d, 'BUSINESS NAME'),
                      onChanged: (_) => setState(() => _businessDirty = true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bizBioCtrl,
                      minLines: 2,
                      maxLines: 4,
                      style: dashProfileInputTextStyle(d),
                      decoration: dashProfileInputDecoration(d, 'BIO'),
                      onChanged: (_) => setState(() => _businessDirty = true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bizEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: dashProfileInputTextStyle(d),
                      decoration: dashProfileInputDecoration(d, 'PUBLIC EMAIL'),
                      onChanged: (_) => setState(() => _businessDirty = true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bizPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: dashProfileInputTextStyle(d),
                      decoration: dashProfileInputDecoration(d, 'PUBLIC PHONE'),
                      onChanged: (_) => setState(() => _businessDirty = true),
                    ),
                  ],
                ),
              ),
            ],
          );

          final body = wide
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 240, child: left),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
                          child: sections,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [left, const SizedBox(height: 16), sections],
                );

          return body;
        },
      ),
    );
  }
}

class _ProviderSummaryCard extends StatelessWidget {
  const _ProviderSummaryCard({
    required this.d,
    required this.user,
    required this.email,
    required this.photoUrl,
    required this.uploading,
    required this.counts,
    required this.onPhoto,
  });

  final DashboardTokens d;
  final User? user;
  final String email;
  final String? photoUrl;
  final bool uploading;
  final ProviderProfileCounts counts;
  final VoidCallback? onPhoto;

  String _initials() {
    final n = user?.displayName?.trim();
    if (n != null && n.isNotEmpty) {
      final parts = n.split(RegExp(r'\s+'));
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
    }
    final em = email;
    if (em.length >= 2 && em.contains('@')) return em.substring(0, 2).toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'Provider';
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: d.bgSecondary,
        border: Border.all(color: d.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatarCircle(
                d: d,
                size: 80,
                initials: _initials(),
                photoUrl: photoUrl,
                uploading: uploading,
                onTap: onPhoto,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onPhoto,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: d.accentBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: d.bgSecondary, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: d.textFaint), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: d.metricBlueBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Provider Account',
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: d.roleParentText),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(d: d, value: '${counts.listings}', label: 'Listings')),
              const SizedBox(width: 8),
              Expanded(child: _MiniStat(d: d, value: '${counts.inquiries}', label: 'Inquiries')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.d, required this.value, required this.label});

  final DashboardTokens d;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: d.bgPrimary,
        border: Border.all(color: d.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: d.textFaint)),
        ],
      ),
    );
  }
}
