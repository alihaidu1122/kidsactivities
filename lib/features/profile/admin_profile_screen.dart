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

final _adminPendingListingsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(firestoreProvider);
  return db.collection('activities').where('approvalStatus', isEqualTo: 'pending').snapshots().map((s) => s.docs.length);
});

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _seeded = false;
  bool _uploadingPhoto = false;
  bool _dirty = false;
  String? _photoUrl;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _seed(DocumentSnapshot<Map<String, dynamic>>? snap) {
    if (snap == null || !snap.exists) return;
    final data = snap.data() ?? {};
    _photoUrl = data['photoUrl'] as String?;
    _displayNameCtrl.text = (data['displayName'] as String?)?.trim() ?? '';
    _phoneCtrl.text = (data['phone'] as String?) ?? '';
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
      showProfileErrorSnackBar(context, 'Upload failed.');
    }
  }

  Future<void> _save(User user) async {
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
      setState(() => _dirty = false);
      showProfileSuccessSnackBar(context, 'Profile saved.');
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
    final pendingAsync = ref.watch(_adminPendingListingsProvider);
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
          final pending = pendingAsync.maybeWhen(data: (n) => n, orElse: () => 0);

          final left = Container(
            constraints: const BoxConstraints(maxWidth: 280),
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
                      initials: user?.displayName?.trim().isNotEmpty == true
                          ? user!.displayName!.trim().substring(0, 1).toUpperCase()
                          : '?',
                      photoUrl: _photoUrl,
                      uploading: _uploadingPhoto,
                      onTap: user == null ? null : () => _pickPhoto(user),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: user == null ? null : () => _pickPhoto(user),
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
                Text(
                  user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'Administrator',
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: d.textFaint), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: d.metricAmberBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Administrator',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: d.statusPendingText),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: d.bgPrimary,
                    border: Border.all(color: d.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('$pending', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary)),
                      Text('Pending listings', style: GoogleFonts.dmSans(fontSize: 9, color: d.textFaint)),
                    ],
                  ),
                ),
              ],
            ),
          );

          final section = ProfileSectionCard(
            d: d,
            icon: '👤',
            iconBg: d.accentBlueBg,
            title: 'Account',
            showSave: _dirty,
            onSave: user == null ? null : () => _save(user),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _displayNameCtrl,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'DISPLAY NAME'),
                  onChanged: (_) => setState(() => _dirty = true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'PHONE'),
                  onChanged: (_) => setState(() => _dirty = true),
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
                const SizedBox(height: 14),
                Text(
                  'User roles and moderation tools are managed from the Users and Listings sections.',
                  style: GoogleFonts.dmSans(fontSize: 11, height: 1.35, color: d.textFaint),
                ),
              ],
            ),
          );

          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 240, child: left),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
                      child: section,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [left, const SizedBox(height: 16), section],
          );
        },
      ),
    );
  }
}
