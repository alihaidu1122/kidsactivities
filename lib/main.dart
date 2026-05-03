import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Default hash URLs (#/...) make Uri.path "/" only; path URLs match GoRouter locations.
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  // Initialize the DEFAULT Firebase app (required by FirebaseAuth.instance, etc).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: KidsActivitiesApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Legacy wrapper (kept so hot-reload doesn't lose class name references).
    return const ProviderScope(child: KidsActivitiesApp());
  }
}
