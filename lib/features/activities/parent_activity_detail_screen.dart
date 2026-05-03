import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dashboard_tokens.dart';
import 'activity_details_screen.dart';
import 'activity_providers.dart';

class ParentActivityDetailScreen extends ConsumerWidget {
  const ParentActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityByIdProvider(activityId));
    final d = context.dash;

    return async.when(
      loading: () => Scaffold(
        backgroundColor: d.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: d.accentBlue)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: d.bgPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load activity.\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: d.textSecondary),
            ),
          ),
        ),
      ),
      data: (activity) {
        if (activity == null) {
          return Scaffold(
            backgroundColor: d.bgPrimary,
            body: Center(
              child: Text(
                'This activity is no longer available.',
                style: TextStyle(color: d.textMuted),
              ),
            ),
          );
        }
        return ActivityDetailsScreen(activity: activity);
      },
    );
  }
}
