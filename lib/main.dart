import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/pocketbase_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the PocketBase service (restores saved auth if any)
  await PocketBaseService.instance.init();

  runApp(
    const ProviderScope(
      child: RemindfullyApp(),
    ),
  );
}
