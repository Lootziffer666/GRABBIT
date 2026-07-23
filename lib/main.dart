import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/grabbit_shell.dart';
import 'theme/grabbit_theme.dart';
import 'services/clipboard_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ClipboardService.instance.initialize();
  runApp(const ProviderScope(child: GrabbitApp()));
}

/// GRABBIT — Android file manager for people who need to find, select,
/// bundle, and reuse work artifacts. Newest files first. Always.
class GrabbitApp extends StatelessWidget {
  const GrabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GRABBIT',
      debugShowCheckedModeBanner: false,
      theme: GrabbitTheme.dark,
      home: const GrabbitShell(),
    );
  }
}
