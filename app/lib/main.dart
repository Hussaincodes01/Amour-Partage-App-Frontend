import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'backend/create_backend.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw edge-to-edge behind transparent system bars.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Load the saved theme and start the backend in parallel.
  final theme = ThemeController.load();
  final backend = createBackend();
  runApp(AmourApp(theme: await theme, backend: await backend));
}
