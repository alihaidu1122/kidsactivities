import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/dashboard_tokens.dart';
import '../auth/auth_providers.dart';
import '../dashboards/parent/parent_nav.dart';
import 'parent_profile_counts_provider.dart';
import 'profile_categories_provider.dart';
import 'profile_avatar_circle.dart';
import 'profile_feedback.dart';
import 'profile_field_styles.dart';
import 'user_profile_providers.dart';

const _cityOptions = ['Tallinn', 'Tartu', 'Pärnu', 'Other'];

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  ConsumerState<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String _city = _cityOptions.first;
  String _languageCode = 'et';

  bool _seeded = false;
  bool _uploadingPhoto = false;
  bool _accountDirty = false;
  bool _familyDirty = false;

  String? _photoUrl;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  void _seedFromDoc(DocumentSnapshot<Map<String, dynamic>>? snap, User? authUser) {
    if (snap == null || !snap.exists) return;
    final data = snap.data() ?? {};
    final pp = data['parentProfile'] as Map<String, dynamic>?;
    _photoUrl = data['photoUrl'] as String?;

    var dn = (data['displayName'] as String?)?.trim() ?? '';
    final fn = (pp?['firstName'] as String?)?.trim() ?? '';
    final ln = (pp?['lastName'] as String?)?.trim() ?? '';
    if (dn.isEmpty && (fn.isNotEmpty || ln.isNotEmpty)) {
      dn = '$fn $ln'.trim();
    }
    _displayNameCtrl.text = dn;
    _phoneCtrl.text = (pp?['phone'] as String?) ?? (data['phone'] as String?) ?? '';
    _firstCtrl.text = fn;
    _lastCtrl.text = ln;

    final rawCity = (pp?['city'] as String?)?.trim() ?? '';
    _city = _cityOptions.contains(rawCity) ? rawCity : (rawCity.isEmpty ? _cityOptions.first : 'Other');
    if (!_cityOptions.contains(rawCity) && rawCity.isNotEmpty && rawCity != 'Other') {
      _city = 'Other';
    }

    _languageCode = (pp?['preferredLanguage'] as String?) ?? 'et';
    if (!['et', 'en', 'ru'].contains(_languageCode)) _languageCode = 'et';
  }

  Future<void> _pickProfilePhoto(User user) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      showProfileErrorSnackBar(context, 'Failed to upload photo. Try again.');
    }
  }

  Future<void> _saveAccount(User user) async {
    final db = ref.read(firestoreProvider);
    try {
      final display = _displayNameCtrl.text.trim();
      if (display.isNotEmpty) {
        await user.updateDisplayName(display);
      }
      await db.doc('users/${user.uid}').set({
        'displayName': display,
        'updatedAt': FieldValue.serverTimestamp(),
        'parentProfile': {
          'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _accountDirty = false);
      showProfileSuccessSnackBar(context, 'Account info saved.');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, 'Could not save: $e');
    }
  }

  Future<void> _saveFamily(User user) async {
    final db = ref.read(firestoreProvider);
    try {
      await db.doc('users/${user.uid}').set({
        'updatedAt': FieldValue.serverTimestamp(),
        'parentProfile': {
          'firstName': _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
          'lastName': _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
          'city': _city,
          'preferredLanguage': _languageCode,
          'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _familyDirty = false);
      showProfileSuccessSnackBar(context, 'Family info saved.');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, 'Could not save: $e');
    }
  }

  Future<void> _showChangePasswordDialog(User user) async {
    if (!user.providerData.any((p) => p.providerId == 'password')) {
      showProfileErrorSnackBar(context, 'Password change is only available for email/password accounts.');
      return;
    }
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = ctx.dash;
        return AlertDialog(
          backgroundColor: d.bgSecondary,
          title: Text('Change password', style: TextStyle(color: d.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'Current password'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: next,
                  obscureText: true,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'New password'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'Confirm new password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: d.textMuted))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    if (next.text != confirm.text) {
      showProfileErrorSnackBar(context, 'New passwords do not match.');
      return;
    }
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: current.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(next.text);
      if (!mounted) return;
      showProfileSuccessSnackBar(context, 'Password updated.');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, 'Could not update password: $e');
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _confirmDeleteAccount(User user) async {
    final typed = TextEditingController();
    final password = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = ctx.dash;
        return AlertDialog(
          backgroundColor: d.bgSecondary,
          title: Text('Delete account', style: TextStyle(color: d.statusRejectedText)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This cannot be undone. Type DELETE to confirm.',
                  style: TextStyle(color: d.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: typed,
                  style: dashProfileInputTextStyle(d),
                  decoration: dashProfileInputDecoration(d, 'Type DELETE'),
                ),
                if (user.providerData.any((p) => p.providerId == 'password')) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: true,
                    style: dashProfileInputTextStyle(d),
                    decoration: dashProfileInputDecoration(d, 'Account password'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: d.textMuted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: d.statusRejectedText),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;
    if (typed.text.trim() != 'DELETE') {
      showProfileErrorSnackBar(context, 'Confirmation text did not match.');
      return;
    }

    final db = ref.read(firestoreProvider);
    final uid = user.uid;

    try {
      if (user.providerData.any((p) => p.providerId == 'password')) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: password.text);
        await user.reauthenticateWithCredential(cred);
      }

      Future<void> batchedUpdates(QuerySnapshot<Map<String, dynamic>> snap, Map<String, dynamic> patch) async {
        for (var i = 0; i < snap.docs.length; i += 400) {
          final batch = db.batch();
          for (final doc in snap.docs.skip(i).take(400)) {
            batch.update(doc.reference, patch);
          }
          await batch.commit();
        }
      }

      final reviews = await db.collection('reviews').where('parentUserId', isEqualTo: uid).get();
      await batchedUpdates(reviews, {
        'parentName': 'Anonymous',
        'parentEmail': FieldValue.delete(),
        'parentPhone': FieldValue.delete(),
      });

      final inquiries = await db.collection('inquiries').where('parentUserId', isEqualTo: uid).get();
      await batchedUpdates(inquiries, {
        'parentName': 'Anonymous',
        'parentEmail': FieldValue.delete(),
        'parentPhone': FieldValue.delete(),
      });

      final childrenSnap = await db.collection('users').doc(uid).collection('children').get();
      for (var i = 0; i < childrenSnap.docs.length; i += 400) {
        final batch = db.batch();
        for (final doc in childrenSnap.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await db.collection('users').doc(uid).delete();
      await user.delete();
      if (!mounted) return;
      context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      showProfileErrorSnackBar(context, 'Could not delete account: $e');
    }
    typed.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    final docAsync = ref.watch(userDocProvider);
    final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
    final countsAsync = ref.watch(parentProfileCountsProvider);
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= parentNavBreakpoint;

    return Material(
      color: d.bgPrimary,
      child: docAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: d.accentBlue)),
        error: (e, _) => Center(child: Text('Could not load profile.\n$e', style: TextStyle(color: d.textMuted))),
        data: (snap) {
          if (!_seeded && snap != null && snap.exists && user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _seedFromDoc(snap, user);
              setState(() => _seeded = true);
            });
          }

          final email = user?.email ?? '—';
          final counts = countsAsync.maybeWhen(data: (c) => c, orElse: () => const ParentProfileCounts(children: 0, inquiries: 0, reviews: 0));

          final leftCard = _LeftSummaryCard(
            d: d,
            user: user,
            email: email,
            photoUrl: _photoUrl,
            uploading: _uploadingPhoto,
            counts: counts,
            onPickPhoto: user == null ? null : () => _pickProfilePhoto(user),
            onChangePassword: user == null ? null : () => _showChangePasswordDialog(user),
            onDeleteAccount: user == null ? null : () => _confirmDeleteAccount(user),
            horizontalHeader: !isWide,
          );

          final sections = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                d: d,
                icon: '👤',
                iconBg: d.accentBlueBg,
                title: 'Account info',
                showSave: _accountDirty,
                onSave: user == null ? null : () => _saveAccount(user),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: dashProfileInputTextStyle(d),
                            keyboardType: TextInputType.phone,
                            decoration: dashProfileInputDecoration(d, 'PHONE'),
                            onChanged: (_) {
                              setState(() {
                                _accountDirty = true;
                                _familyDirty = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('EMAIL', style: dashProfileLabelStyle(d)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
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
                      'Email cannot be changed. Contact support if needed.',
                      style: GoogleFonts.dmSans(fontSize: 10, color: d.textFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                d: d,
                icon: '🏠',
                iconBg: d.metricGreenBg,
                title: 'Family info',
                showSave: _familyDirty,
                onSave: user == null ? null : () => _saveFamily(user),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _firstCtrl,
                            style: dashProfileInputTextStyle(d),
                            decoration: dashProfileInputDecoration(d, 'FIRST NAME'),
                            onChanged: (_) => setState(() => _familyDirty = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lastCtrl,
                            style: dashProfileInputTextStyle(d),
                            decoration: dashProfileInputDecoration(d, 'LAST NAME'),
                            onChanged: (_) => setState(() => _familyDirty = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _CityDropdown(d: d, value: _city, onChanged: (v) => setState(() { _city = v; _familyDirty = true; }))),
                        const SizedBox(width: 12),
                        Expanded(child: _LanguageDropdown(d: d, code: _languageCode, onChanged: (c) => setState(() { _languageCode = c; _familyDirty = true; }))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ChildrenSection(
                parentUid: user?.uid,
                onChanged: () {},
              ),
            ],
          );

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 240, child: leftCard),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: parentContentBottomPadding(context)),
                      child: sections,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, parentContentBottomPadding(context) + 16),
            children: [
              leftCard,
              const SizedBox(height: 16),
              sections,
              if (!isWide) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: user == null ? null : () => _showChangePasswordDialog(user),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: d.borderColor),
                      backgroundColor: d.bgTertiary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('🔑 Change Password', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: d.textSecondary)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: user == null ? null : () => _confirmDeleteAccount(user),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: d.statusRejectedBg),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('🗑 Delete Account', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: d.statusRejectedText)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.d, required this.value, required this.onChanged});

  final DashboardTokens d;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      dropdownColor: d.bgSecondary,
      style: dashProfileInputTextStyle(d),
      decoration: dashProfileInputDecoration(d, 'CITY'),
      items: [
        for (final c in _cityOptions)
          DropdownMenuItem(value: c, child: Text(c, style: dashProfileInputTextStyle(d), overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.d, required this.code, required this.onChanged});

  final DashboardTokens d;
  final String code;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(code),
      initialValue: code,
      isExpanded: true,
      dropdownColor: d.bgSecondary,
      style: dashProfileInputTextStyle(d),
      decoration: dashProfileInputDecoration(d, 'LANGUAGE'),
      items: [
        DropdownMenuItem(value: 'et', child: Text('Estonian', style: dashProfileInputTextStyle(d), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'en', child: Text('English', style: dashProfileInputTextStyle(d), overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'ru', child: Text('Russian', style: dashProfileInputTextStyle(d), overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _LeftSummaryCard extends StatelessWidget {
  const _LeftSummaryCard({
    required this.d,
    required this.user,
    required this.email,
    required this.photoUrl,
    required this.uploading,
    required this.counts,
    required this.onPickPhoto,
    required this.onChangePassword,
    required this.onDeleteAccount,
    required this.horizontalHeader,
  });

  final DashboardTokens d;
  final User? user;
  final String email;
  final String? photoUrl;
  final bool uploading;
  final ParentProfileCounts counts;
  final VoidCallback? onPickPhoto;
  final VoidCallback? onChangePassword;
  final VoidCallback? onDeleteAccount;
  final bool horizontalHeader;

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
    final name = user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'No name set';

    Widget avatarStack({required double size}) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ProfileAvatarCircle(
            d: d,
            size: size,
            initials: _initials(),
            photoUrl: photoUrl,
            uploading: uploading,
            onTap: onPickPhoto,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onPickPhoto,
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
      );
    }

    final roleBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: d.accentBlueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Parent Account',
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: d.roleParentText),
      ),
    );

    final stats = Row(
      children: [
        Expanded(child: _StatBox(d: d, value: '${counts.children}', label: 'Children')),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(d: d, value: '${counts.inquiries}', label: 'Inquiries')),
        const SizedBox(width: 8),
        Expanded(child: _StatBox(d: d, value: '${counts.reviews}', label: 'Reviews')),
      ],
    );

    final body = Column(
      crossAxisAlignment: horizontalHeader ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (horizontalHeader)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarStack(size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: d.textFaint)),
                    const SizedBox(height: 8),
                    roleBadge,
                  ],
                ),
              ),
            ],
          )
        else ...[
          avatarStack(size: 80),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(email, style: GoogleFonts.dmSans(fontSize: 11, color: d.textFaint), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          roleBadge,
        ],
        const SizedBox(height: 12),
        stats,
        if (!horizontalHeader) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChangePassword,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: d.borderColor),
                backgroundColor: d.bgTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text('🔑 Change Password', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: d.textSecondary)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDeleteAccount,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: d.statusRejectedBg),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text('🗑 Delete Account', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: d.statusRejectedText)),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: horizontalHeader ? double.infinity : 240,
      decoration: BoxDecoration(
        color: d.bgSecondary,
        border: Border.all(color: d.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(24),
      child: body,
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.d, required this.value, required this.label});

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
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: d.textFaint)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.d,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.showSave,
    required this.onSave,
    required this.child,
  });

  final DashboardTokens d;
  final String icon;
  final Color iconBg;
  final String title;
  final bool showSave;
  final VoidCallback? onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: d.bgSecondary,
        border: Border.all(color: d.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: d.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showSave && onSave != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: d.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Save', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChildrenSection extends ConsumerStatefulWidget {
  const _ChildrenSection({required this.parentUid, required this.onChanged});

  final String? parentUid;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ChildrenSection> createState() => _ChildrenSectionState();
}

class _ChildrenSectionState extends ConsumerState<_ChildrenSection> {
  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    final uid = widget.parentUid;
    if (uid == null) {
      return _SectionCard(
        d: d,
        icon: '👶',
        iconBg: d.metricAmberBg,
        title: 'Children',
        showSave: false,
        onSave: null,
        child: Text('Sign in to manage children.', style: TextStyle(color: d.textMuted)),
      );
    }

    return _SectionCard(
      d: d,
      icon: '👶',
      iconBg: d.metricAmberBg,
      title: 'Children',
      showSave: false,
      onSave: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _openChildEditor(context, ref, uid, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: d.accentBlueBg,
                foregroundColor: d.roleParentText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('+ Add Child', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ref.read(firestoreProvider).collection('users').doc(uid).collection('children').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: d.accentBlue, strokeWidth: 2)),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: d.bgPrimary,
                    border: Border.all(color: d.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text('👶', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text('No children added yet.', style: GoogleFonts.dmSans(fontSize: 12, color: d.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        'Add a child to get personalised activity recommendations.',
                        style: GoogleFonts.dmSans(fontSize: 10, color: d.textFaint),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final doc in docs)
                    _ChildRowCard(
                      d: d,
                      doc: doc,
                      onEdit: () => _openChildEditor(context, ref, uid, doc),
                      onDelete: () => _deleteChild(context, ref, doc.reference),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChild(BuildContext context, WidgetRef ref, DocumentReference<Map<String, dynamic>> docRef) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove child?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await docRef.delete();
      widget.onChanged();
    }
  }

  Future<void> _openChildEditor(
    BuildContext context,
    WidgetRef ref,
    String parentUid,
    QueryDocumentSnapshot<Map<String, dynamic>>? existing,
  ) async {
    await showChildEditorSheet(context, ref, parentUid, existing);
    widget.onChanged();
  }
}

Future<void> showChildEditorSheet(
  BuildContext context,
  WidgetRef ref,
  String parentUid,
  QueryDocumentSnapshot<Map<String, dynamic>>? existing,
) async {
  final d = context.dash;
  final fn = TextEditingController(text: (existing?.data()['firstName'] as String?) ?? '');
  final ln = TextEditingController(text: (existing?.data()['lastName'] as String?) ?? '');
  final age = TextEditingController(text: '${(existing?.data()['age'] as num?)?.toInt() ?? ''}');
  final db = ref.read(firestoreProvider);

  var interests = List<String>.from((existing?.data()['interests'] as List?)?.cast<String>() ?? []);

  final wide = MediaQuery.sizeOf(context).width >= 600;

  Future<void> submit() async {
    final coll = db.collection('users').doc(parentUid).collection('children');
    final doc = existing?.reference ?? coll.doc();
    await doc.set({
      'childId': doc.id,
      'parentUserId': parentUid,
      'firstName': fn.text.trim(),
      'lastName': ln.text.trim().isEmpty ? null : ln.text.trim(),
      'age': int.tryParse(age.text.trim()),
      'dateOfBirth': null,
      'interests': interests,
      'updatedAt': FieldValue.serverTimestamp(),
      if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final catsAsync = ref.watch(profileInterestCategoriesProvider);
            final categories = catsAsync.maybeWhen(
              data: (l) => l,
              orElse: () => ['Sports', 'Arts', 'Music', 'STEM', 'Outdoor'],
            );

            return AlertDialog(
              backgroundColor: d.bgSecondary,
              insetPadding: wide ? const EdgeInsets.symmetric(horizontal: 80, vertical: 40) : EdgeInsets.zero,
              title: Text(existing == null ? 'Add child' : 'Edit child', style: TextStyle(color: d.textPrimary)),
              content: SizedBox(
                width: wide ? 420 : double.maxFinite,
                child: StatefulBuilder(
                  builder: (ctx, setLocal) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: fn,
                                  style: dashProfileInputTextStyle(d),
                                  decoration: dashProfileInputDecoration(d, 'FIRST NAME'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: ln,
                                  style: dashProfileInputTextStyle(d),
                                  decoration: dashProfileInputDecoration(d, 'LAST NAME'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: age,
                            keyboardType: TextInputType.number,
                            style: dashProfileInputTextStyle(d),
                            decoration: dashProfileInputDecoration(d, 'AGE'),
                          ),
                          const SizedBox(height: 12),
                          Text('INTERESTS', style: dashProfileLabelStyle(d)),
                          const SizedBox(height: 6),
                          if (catsAsync.isLoading)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator(color: d.accentBlue, strokeWidth: 2)),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in categories)
                                  FilterChip(
                                    label: Text(
                                      c,
                                      style: GoogleFonts.dmSans(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    selected: interests.contains(c),
                                    selectedColor: d.accentBlue,
                                    checkmarkColor: Colors.white,
                                    labelStyle: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: interests.contains(c) ? Colors.white : d.textMuted,
                                    ),
                                    backgroundColor: d.bgTertiary,
                                    side: BorderSide(color: d.borderColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (sel) {
                                      setLocal(() {
                                        if (sel) {
                                          interests = [...interests, c];
                                        } else {
                                          interests = interests.where((x) => x != c).toList();
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: d.textMuted)),
                ),
                FilledButton(
                  onPressed: () async {
                    await submit();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    fn.dispose();
    ln.dispose();
    age.dispose();
  }
}

class _ChildRowCard extends StatelessWidget {
  const _ChildRowCard({
    required this.d,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  final DashboardTokens d;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final first = (data['firstName'] as String?) ?? '';
    final last = (data['lastName'] as String?)?.trim() ?? '';
    final name = '$first ${last.isEmpty ? '' : last}'.trim();
    final age = (data['age'] as num?)?.toInt();
    final emoji = first.toLowerCase().startsWith('m') ? '👦' : '👧';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: d.bgPrimary,
        border: Border.all(color: d.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: d.bgTertiary, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Child' : name,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: d.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Age ${age ?? '—'}', style: GoogleFonts.dmSans(fontSize: 11, color: d.textFaint)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.edit_outlined, size: 18, color: d.textFaint),
            onPressed: onEdit,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.delete_outline, size: 18, color: d.statusRejectedText),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
