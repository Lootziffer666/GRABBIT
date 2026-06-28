import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/grabbit_colors.dart';
import 'recent_screen.dart';
import 'downloads_screen.dart';
import 'search_screen.dart';
import 'app_manager_screen.dart';
import 'settings_screen.dart';

/// The GRABBIT Shell — bottom navigation that hosts all main screens.
/// 5 tabs: Recent, Downloads, Search, Apps, Settings.
///
/// Design: FLUBBER dark-matte, turquoise accent for active tab.
/// Physical sticker-like tab bar (inset shadow, no elevation).
class GrabbitShell extends StatefulWidget {
  const GrabbitShell({super.key});

  @override
  State<GrabbitShell> createState() => _GrabbitShellState();
}

class _GrabbitShellState extends State<GrabbitShell> {
  int _currentIndex = 0;

  final _screens = const [
    RecentScreen(),
    DownloadsScreen(),
    SearchScreen(),
    AppManagerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: GrabbitColors.surface,
        border: Border(
          top: BorderSide(color: GrabbitColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.access_time_rounded, 'Recent'),
              _navItem(1, Icons.download_rounded, 'Downloads'),
              _navItem(2, Icons.search_rounded, 'Suche'),
              _navItem(3, Icons.apps_rounded, 'Apps'),
              _navItem(4, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? GrabbitColors.turquoise.withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? GrabbitColors.turquoise : GrabbitColors.t3,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? GrabbitColors.turquoise : GrabbitColors.t4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
