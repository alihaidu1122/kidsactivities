import 'package:flutter/material.dart';

import 'parent/parent_app_redirect.dart';

/// Parent UX lives under `/parent/*` with [ParentResponsiveLayout] in [routerProvider].
/// Kept as a thin alias so any old imports of `ParentDashboard` still compile.
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) => const ParentAppShellRedirect();
}
