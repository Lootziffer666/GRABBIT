import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/grabbit_colors.dart';
import 'recent_screen.dart';
import 'downloads_screen.dart';
import 'search_screen.dart';
import 'app_manager_screen.dart';

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
    _SettingsPlaceholder(),
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

/// Placeholder for the settings screen.
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrabbitColors.void_,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              _settingsItem(context, 'Index neu aufbauen', 'Vollständiger MediaStore-Scan', Icons.refresh_rounded),
              _settingsItem(context, 'Reduce Motion', 'Animationen minimieren', Icons.motion_photos_off_rounded),
              _settingsItem(context, 'Standard-Sortierung', 'Neueste zuerst', Icons.sort_rounded),
              _settingsItem(context, 'Sharesheet-Favoriten', '5 Ziele konfiguriert', Icons.share_rounded),
              _settingsItem(context, 'Export / Backup', 'Index als JSON exportieren', Icons.save_alt_rounded),
              _settingsItem(context, 'Über GRABBIT', 'v0.1.0 · GPL-3.0 · FLUBBER Design', Icons.info_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GrabbitColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GrabbitColors.t2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GrabbitColors.t1)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: GrabbitColors.t3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: GrabbitColors.t4),
        ],
      ),
    );
  }
}
