import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';

class AdminToolsScreen extends ConsumerStatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  ConsumerState<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends ConsumerState<AdminToolsScreen> {
  bool _working = false;

  Future<void> _seed() async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(firestoreProvider);

      // Seed categories if empty.
      final categoriesSnap = await db.collection('categories').limit(1).get();
      if (categoriesSnap.docs.isEmpty) {
        final batch = db.batch();
        final categories = <({String name, String icon, int sort})>[
          (name: 'Football/Soccer', icon: '⚽', sort: 10),
          (name: 'Swimming', icon: '🏊', sort: 20),
          (name: 'Painting & Drawing', icon: '🎨', sort: 30),
          (name: 'Piano', icon: '🎹', sort: 40),
          (name: 'Coding', icon: '💻', sort: 50),
          (name: 'Robotics', icon: '🤖', sort: 60),
          (name: 'Forest School', icon: '🌲', sort: 70),
          (name: 'Chess', icon: '🧠', sort: 80),
        ];
        for (final c in categories) {
          final refDoc = db.collection('categories').doc();
          batch.set(refDoc, {
            'categoryId': refDoc.id,
            'categoryName': '${c.icon} ${c.name}',
            'categoryNameEt': null,
            'categoryNameRu': null,
            'icon': c.icon,
            'isActive': true,
            'sortOrder': c.sort,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      // Seed activities if empty (so parent feed shows UI).
      final activitiesSnap = await db.collection('activities').limit(1).get();
      if (activitiesSnap.docs.isEmpty) {
        final now = DateTime.now();
        final demo = [
          {
            'title': 'Swimming for Beginners',
            'category': '🏊 Swimming',
            'city': 'Tallinn',
            'ageMin': 4,
            'ageMax': 10,
            'price': 15,
            'priceType': 'per_session',
          },
          {
            'title': 'Kids Coding Club',
            'category': '💻 Coding',
            'city': 'Tartu',
            'ageMin': 8,
            'ageMax': 14,
            'price': 59,
            'priceType': 'monthly',
          },
          {
            'title': 'Art Studio: Painting',
            'category': '🎨 Painting & Drawing',
            'city': 'Pärnu',
            'ageMin': 5,
            'ageMax': 12,
            'price': 12,
            'priceType': 'per_session',
          },
          {
            'title': 'Forest School (Outdoor)',
            'category': '🌲 Forest School',
            'city': 'Tallinn',
            'ageMin': 3,
            'ageMax': 7,
            'price': 0,
            'priceType': 'free',
          },
        ];

        final batch = db.batch();
        for (var i = 0; i < demo.length; i++) {
          final refDoc = db.collection('activities').doc();
          final d = demo[i];
          batch.set(refDoc, {
            'activityId': refDoc.id,
            'providerUserId': 'demo_provider_${i + 1}',
            'providerBusinessName': 'Demo Provider ${i + 1}',
            'title': d['title'],
            'description':
                'Demo listing created for UI preview. Replace with real provider content later.',
            'category': d['category'],
            'subCategory': null,
            'ageRangeMin': d['ageMin'],
            'ageRangeMax': d['ageMax'],
            'city': d['city'],
            'address': 'Demo address',
            'locationName': 'Demo location',
            'priceAmount': d['price'],
            'priceCurrency': 'EUR',
            'priceType': d['priceType'],
            'priceNotes': null,
            'scheduleType': 'weekly',
            'scheduleDetails': 'Mon/Wed 17:00-18:00 (demo)',
            'startDate': null,
            'endDate': null,
            'photos': <String>[],
            'videoUrl': null,
            'languages': <String>['Estonian', 'English', 'Russian'],
            'maxParticipants': null,
            'createdAt': Timestamp.fromDate(now.subtract(Duration(days: i * 2))),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'approvalStatus': 'approved',
            'rejectionReason': null,
            'viewCount': 0,
            'inquiryCount': 0,
          });
        }
        await batch.commit();
      }

      messenger.showSnackBar(const SnackBar(content: Text('Demo data seeded.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Seed failed: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Admin tools', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Use these only for previewing UI. Remove/disable in production builds later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _working ? null : _seed,
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(_working ? 'Seeding…' : 'Seed demo data'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

