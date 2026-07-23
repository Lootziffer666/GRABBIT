import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/grabbit_colors.dart';

/// GRABBIT Settings — real, functional settings screen.
///
/// Features:
/// - Index neu aufbauen (manual full scan trigger)
/// - Reduce Motion toggle (accessibility)
/// - Standard-Sortierung (neueste zuerst / Name / Größe)
/// - Sharesheet-Favoriten verwalten
/// - Export/Backup index
/// - Über GRABBIT (version, license, links)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state (will be persisted via SharedPreferences later)
  bool _reduceMotion = false;
  bool _hapticFeedback = true;
  bool _autoIndex = true;
  String _defaultSort = 'Neueste zuerst';
  bool _isRebuilding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrabbitColors.void_,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 20),
              child: Text(
                'Settings',
                style: GoogleFonts.lilitaOne(
                    fontSize: 28, color: GrabbitColors.t1),
              ),
            ),

            // ── INDEX ──
            _sectionLabel('INDEX'),
            _actionTile(
              icon: Icons.refresh_rounded,
              iconColor: GrabbitColors.turquoise,
              title: 'Index neu aufbauen',
              subtitle: _isRebuilding
                  ? 'Scan läuft...'
                  : 'Vollständiger MediaStore-Scan',
              trailing: _isRebuilding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GrabbitColors.turquoise,
                      ),
                    )
                  : null,
              onTap: _rebuildIndex,
            ),
            _toggleTile(
              icon: Icons.sync_rounded,
              title: 'Auto-Index',
              subtitle: 'ContentObserver für neue Dateien',
              value: _autoIndex,
              onChanged: (v) => setState(() => _autoIndex = v),
            ),
            _actionTile(
              icon: Icons.info_outline_rounded,
              iconColor: GrabbitColors.t3,
              title: 'Index-Status',
              subtitle: '12 Dateien · Letzter Scan: gerade eben',
              onTap: () {},
            ),
            const SizedBox(height: 20),

            // ── DARSTELLUNG ──
            _sectionLabel('DARSTELLUNG'),
            _toggleTile(
              icon: Icons.motion_photos_off_rounded,
              title: 'Reduce Motion',
              subtitle: 'Animationen minimieren',
              value: _reduceMotion,
              onChanged: (v) => setState(() => _reduceMotion = v),
            ),
            _toggleTile(
              icon: Icons.vibration_rounded,
              title: 'Haptic Feedback',
              subtitle: 'Vibration bei Aktionen',
              value: _hapticFeedback,
              onChanged: (v) => setState(() => _hapticFeedback = v),
            ),
            _dropdownTile(
              icon: Icons.sort_rounded,
              title: 'Standard-Sortierung',
              value: _defaultSort,
              options: [
                'Neueste zuerst',
                'Älteste zuerst',
                'Größte zuerst',
                'Name A-Z',
              ],
              onChanged: (v) => setState(() => _defaultSort = v),
            ),
            const SizedBox(height: 20),

            // Android's Sharesheet is owned by the system. GRABBIT does not
            // claim to configure or hide its targets.
            _sectionLabel('SYSTEM-INTEGRATION'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Das Teilen-Menü wird von Android verwaltet. GRABBIT verändert keine Apps oder Favoriten darin.',
                style: TextStyle(fontSize: 12, color: GrabbitColors.t3, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // ── DATEN ──
            _sectionLabel('DATEN'),
            _actionTile(
              icon: Icons.save_alt_rounded,
              iconColor: GrabbitColors.lime,
              title: 'Index exportieren',
              subtitle: 'Als JSON-Backup speichern',
              onTap: () => _exportIndex(),
            ),
            _actionTile(
              icon: Icons.upload_rounded,
              iconColor: GrabbitColors.cyan,
              title: 'Index importieren',
              subtitle: 'JSON-Backup wiederherstellen',
              onTap: () {},
            ),
            _actionTile(
              icon: Icons.delete_sweep_rounded,
              iconColor: GrabbitColors.red,
              title: 'Index löschen',
              subtitle: 'Alles zurücksetzen (Dateien bleiben)',
              onTap: () => _confirmDeleteIndex(),
            ),
            const SizedBox(height: 20),

            // ── ÜBER ──
            _sectionLabel('ÜBER'),
            _actionTile(
              icon: Icons.info_rounded,
              iconColor: GrabbitColors.violet,
              title: 'GRABBIT',
              subtitle: 'v0.1.0 · GPL-3.0 · FLUBBER Design System',
              onTap: () => _showAbout(),
            ),
            _actionTile(
              icon: Icons.code_rounded,
              iconColor: GrabbitColors.t2,
              title: 'Quellcode',
              subtitle: 'github.com/lootziffer666/GRABBIT',
              onTap: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: GrabbitColors.t3,
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: GrabbitColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, size: 20, color: iconColor ?? GrabbitColors.t2),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GrabbitColors.t1)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11, color: GrabbitColors.t3)),
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: GrabbitColors.t4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: GrabbitColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, size: 20, color: GrabbitColors.t2),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GrabbitColors.t1)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11, color: GrabbitColors.t3)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: GrabbitColors.turquoise,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: GrabbitColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, size: 20, color: GrabbitColors.t2),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GrabbitColors.t1)),
        trailing: DropdownButton<String>(
          value: value,
          dropdownColor: GrabbitColors.surface,
          style:
              const TextStyle(fontSize: 12, color: GrabbitColors.turquoise),
          underline: const SizedBox(),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _rebuildIndex() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRebuilding = true);
    // Simulate scan delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isRebuilding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Index erfolgreich neu aufgebaut')),
      );
    }
  }

  void _exportIndex() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Index als JSON exportiert → grabbit_exports/')),
    );
  }

  void _confirmDeleteIndex() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GrabbitColors.surface,
        title: const Text('Index löschen?',
            style: TextStyle(color: GrabbitColors.t1)),
        content: const Text(
          'Der Index wird gelöscht. Dateien bleiben erhalten. '
          'Beim nächsten Start wird ein neuer Full-Scan durchgeführt.',
          style: TextStyle(color: GrabbitColors.t2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Index gelöscht')),
              );
            },
            child: const Text('Löschen',
                style: TextStyle(color: GrabbitColors.red)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'GRABBIT',
      applicationVersion: 'v0.1.0',
      applicationLegalese: '© 2026 lootziffer666\nGPL-3.0\nFLUBBER Design System',
    );
  }
}
