import 'package:flutter/material.dart';

import 'screens/recent_screen.dart';
import 'theme/grabbit_theme.dart';

void main() {
  runApp(const GrabbitApp());
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
      home: const RecentScreen(),
    );
  }
}
