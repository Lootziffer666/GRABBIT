import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';

/// App Manager Screen — not a launcher, not a cleaner.
/// A tool for understanding what's installed, what's unused, what opens what.
///
/// Features:
/// - Sortieren nach Installationsdatum
/// - Nie geöffnet / lange nicht genutzt
/// - App-Details, deinstallieren
/// - "Welche App kann diese Datei öffnen?"
/// - "Welche Apps tauchen im Sharesheet unnötig auf?"
/// - Nicht "ungenutzt = löschen" — sondern: ungeprüft / behalten / später
class AppManagerScreen extends StatefulWidget {
  const AppManagerScreen({super.key});

  @override
  State<AppManagerScreen> createState() => _AppManagerScreenState();
}

enum AppFilter {
  all,
  neverOpened,
  longUnused,
  recent,
  large,
  system;

  String get label => switch (this) {
        all => 'Alle',
        neverOpened => 'Nie geöffnet',
        longUnused => 'Lange ungenutzt',
        recent => 'Kürzlich installiert',
        large => 'Große Apps',
        system => 'System',
      };
}

/// Triage status — not "delete", but "what do I think about this?"
enum AppTriage {
  unchecked, // default — not yet reviewed
  keep, // intentionally keeping
  later, // will check later
  remove; // ready to uninstall

  String get label => switch (this) {
        unchecked => 'Ungeprüft',
        keep => 'Behalten',
        later => 'Später',
        remove => 'Weg',
      };

  Color get color => switch (this) {
        unchecked => GrabbitColors.t3,
        keep => GrabbitColors.stable,
        later => GrabbitColors.yellow,
        remove => GrabbitColors.red,
      };

  IconData get icon => switch (this) {
        unchecked => Icons.help_outline_rounded,
        keep => Icons.check_circle_outline_rounded,
        later => Icons.schedule_rounded,
        remove => Icons.delete_outline_rounded,
      };
}

/// Demo app data (will be replaced by platform channel data).
class InstalledApp {
  final String package;
  final String label;
  final int installed; // epoch ms
  final int? lastUsed;
  final int sizeBytes;
  final bool isSystem;
  final bool neverOpened;
  AppTriage triage;

  InstalledApp({
    required this.package,
    required this.label,
    required this.installed,
    this.lastUsed,
    this.sizeBytes = 0,
    this.isSystem = false,
    this.neverOpened = false,
    this.triage = AppTriage.unchecked,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get installedAgo {
    final days = (DateTime.now().millisecondsSinceEpoch - installed) ~/ 86400000;
    if (days == 0) return 'heute';
    if (days == 1) return 'gestern';
    if (days < 30) return 'vor $days Tagen';
    if (days < 365) return 'vor ${days ~/ 30} Monaten';
    return 'vor ${days ~/ 365} Jahren';
  }
}

class _AppManagerScreenState extends State<AppManagerScreen> {
  AppFilter _filter = AppFilter.all;
  late List<InstalledApp> _apps;

  @override
  void initState() {
    super.initState();
    _apps = _generateDemoApps();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter();

    return Scaffold(
      backgroundColor: GrabbitColors.void_,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Apps',
                    style: GoogleFonts.lilitaOne(
                      fontSize: 28,
                      color: GrabbitColors.t1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GrabbitColors.violet.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: GrabbitColors.violet.withAlpha(60)),
                    ),
                    child: Text(
                      '${_apps.length} installiert',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.violet,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: AppFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? GrabbitColors.violet.withAlpha(30)
                              : GrabbitColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? GrabbitColors.violet
                                : GrabbitColors.borderStrong,
                          ),
                        ),
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? GrabbitColors.violet
                                : GrabbitColors.t3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // App list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) => ScrollReveal(
                  delay: Duration(milliseconds: i * 30),
                  child: _buildAppCard(filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(InstalledApp app) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: GrabbitColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: app.triage == AppTriage.remove
              ? GrabbitColors.red.withAlpha(80)
              : GrabbitColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAppActions(app),
        onLongPress: () => _cycleTriage(app),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // App icon placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GrabbitColors.violet.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    app.label.isNotEmpty ? app.label[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GrabbitColors.violet,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // App info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.t1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${app.installedAgo} · ${app.sizeFormatted}'
                      '${app.neverOpened ? " · nie geöffnet" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: app.neverOpened
                            ? GrabbitColors.orange
                            : GrabbitColors.t3,
                      ),
                    ),
                  ],
                ),
              ),
              // Triage badge
              GestureDetector(
                onTap: () => _cycleTriage(app),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: app.triage.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: app.triage.color.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(app.triage.icon,
                          size: 12, color: app.triage.color),
                      const SizedBox(width: 4),
                      Text(
                        app.triage.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: app.triage.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleTriage(InstalledApp app) {
    setState(() {
      final values = AppTriage.values;
      final next = (values.indexOf(app.triage) + 1) % values.length;
      app.triage = values[next];
    });
  }

  void _showAppActions(InstalledApp app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GrabbitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: GrabbitColors.t4, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(app.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GrabbitColors.t1)),
            Text(app.package, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: GrabbitColors.t3)),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.open_in_new_rounded, color: GrabbitColors.turquoise), title: const Text('Öffnen'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.info_outline_rounded, color: GrabbitColors.t2), title: const Text('App-Details (System)'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.share_rounded, color: GrabbitColors.t2), title: const Text('APK teilen'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.delete_outline_rounded, color: GrabbitColors.red), title: const Text('Deinstallieren', style: TextStyle(color: GrabbitColors.red)), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<InstalledApp> _applyFilter() {
    return switch (_filter) {
      AppFilter.all => _apps,
      AppFilter.neverOpened => _apps.where((a) => a.neverOpened).toList(),
      AppFilter.longUnused => _apps.where((a) {
          if (a.lastUsed == null) return true;
          return DateTime.now().millisecondsSinceEpoch - a.lastUsed! > 30 * 86400000;
        }).toList(),
      AppFilter.recent => _apps.where((a) =>
          DateTime.now().millisecondsSinceEpoch - a.installed < 7 * 86400000).toList(),
      AppFilter.large => _apps.where((a) => a.sizeBytes > 100 * 1024 * 1024).toList(),
      AppFilter.system => _apps.where((a) => a.isSystem).toList(),
    };
  }

  List<InstalledApp> _generateDemoApps() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      InstalledApp(package: 'com.whatsapp', label: 'WhatsApp', installed: now - 365 * 86400000, lastUsed: now - 3600000, sizeBytes: 210 * 1024 * 1024),
      InstalledApp(package: 'com.spotify.music', label: 'Spotify', installed: now - 200 * 86400000, lastUsed: now - 86400000, sizeBytes: 350 * 1024 * 1024),
      InstalledApp(package: 'org.mozilla.firefox', label: 'Firefox', installed: now - 90 * 86400000, lastUsed: now - 7200000, sizeBytes: 180 * 1024 * 1024),
      InstalledApp(package: 'com.example.neverused', label: 'PDF Expert Pro', installed: now - 60 * 86400000, neverOpened: true, sizeBytes: 95 * 1024 * 1024),
      InstalledApp(package: 'com.some.scanner', label: 'Document Scanner Plus', installed: now - 45 * 86400000, neverOpened: true, sizeBytes: 42 * 1024 * 1024),
      InstalledApp(package: 'com.game.puzzle', label: 'Puzzle Quest', installed: now - 120 * 86400000, lastUsed: now - 90 * 86400000, sizeBytes: 280 * 1024 * 1024),
      InstalledApp(package: 'com.grabbit.grabbit', label: 'GRABBIT', installed: now - 86400000, lastUsed: now - 1800000, sizeBytes: 24 * 1024 * 1024),
      InstalledApp(package: 'com.android.chrome', label: 'Chrome', installed: now - 730 * 86400000, lastUsed: now - 3600000, sizeBytes: 420 * 1024 * 1024, isSystem: true),
      InstalledApp(package: 'com.android.vending', label: 'Play Store', installed: now - 730 * 86400000, lastUsed: now - 7200000, sizeBytes: 150 * 1024 * 1024, isSystem: true),
      InstalledApp(package: 'com.random.tool', label: 'WiFi Analyzer', installed: now - 3 * 86400000, neverOpened: true, sizeBytes: 15 * 1024 * 1024),
    ];
  }
}
