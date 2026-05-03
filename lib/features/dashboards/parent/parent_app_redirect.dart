import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sends parents from the role gate [`/`] into the routed parent shell.
class ParentAppShellRedirect extends ConsumerStatefulWidget {
  const ParentAppShellRedirect({super.key});

  @override
  ConsumerState<ParentAppShellRedirect> createState() => _ParentAppShellRedirectState();
}

class _ParentAppShellRedirectState extends ConsumerState<ParentAppShellRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = GoRouterState.of(context).matchedLocation;
      if (loc == '/' || loc.isEmpty) {
        context.go('/parent/discover');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
