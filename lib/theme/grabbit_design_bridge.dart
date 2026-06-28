import 'package:flutter/material.dart';
import 'package:grabbit_core/grabbit_core.dart';

import 'grabbit_colors.dart';

/// The single bridge between file data and the FLUBBER design system.
/// Maps FileCategory → color, FileState → motion/color.
/// Same pattern as ForgeDesignBridge in App-Lab.
class GrabbitDesignBridge {
  const GrabbitDesignBridge._();
  static const instance = GrabbitDesignBridge._();

  // ── FileCategory → Color ────────────────────────────────────────────────

  Color categoryColor(FileCategory cat) => switch (cat) {
        FileCategory.image => GrabbitColors.turquoise,
        FileCategory.video => GrabbitColors.violet,
        FileCategory.audio => GrabbitColors.pink,
        FileCategory.document => GrabbitColors.orange,
        FileCategory.archive => GrabbitColors.yellow,
        FileCategory.code => GrabbitColors.cyan,
        FileCategory.app => GrabbitColors.lime,
        FileCategory.other => GrabbitColors.muted,
      };

  IconData categoryIcon(FileCategory cat) => switch (cat) {
        FileCategory.image => Icons.image_rounded,
        FileCategory.video => Icons.videocam_rounded,
        FileCategory.audio => Icons.audiotrack_rounded,
        FileCategory.document => Icons.description_rounded,
        FileCategory.archive => Icons.folder_zip_rounded,
        FileCategory.code => Icons.code_rounded,
        FileCategory.app => Icons.android_rounded,
        FileCategory.other => Icons.insert_drive_file_rounded,
      };

  String categoryLabel(FileCategory cat) => switch (cat) {
        FileCategory.image => 'Bild',
        FileCategory.video => 'Video',
        FileCategory.audio => 'Audio',
        FileCategory.document => 'Dokument',
        FileCategory.archive => 'Archiv',
        FileCategory.code => 'Code',
        FileCategory.app => 'App',
        FileCategory.other => 'Datei',
      };

  // ── FileState → Design Tokens ───────────────────────────────────────────

  Color stateColor(FileState state) => switch (state) {
        FileState.stable => GrabbitColors.stable,
        FileState.adapting => GrabbitColors.adapting,
        FileState.actNow => GrabbitColors.actNow,
        FileState.failed => GrabbitColors.failed,
        FileState.recovered => GrabbitColors.recovered,
      };

  /// Border beam active for states that need visual urgency.
  bool stateBeamActive(FileState state) =>
      state == FileState.actNow || state == FileState.failed;

  /// Luminous energy line mode (same concept as KYUUBI).
  String? stateLuminousMode(FileState state) => switch (state) {
        FileState.stable => null,
        FileState.adapting => 'calm',
        FileState.actNow => 'pressure',
        FileState.failed => 'urgent',
        FileState.recovered => null,
      };

  /// Animation duration — faster for urgent states.
  Duration stateAnimDuration(FileState state) => switch (state) {
        FileState.stable => const Duration(milliseconds: 600),
        FileState.adapting => const Duration(milliseconds: 3200),
        FileState.actNow => const Duration(milliseconds: 1800),
        FileState.failed => const Duration(milliseconds: 800),
        FileState.recovered => const Duration(milliseconds: 600),
      };

  /// FLUBBER easing curves.
  Curve stateCurve(FileState state) => switch (state) {
        FileState.stable => Curves.easeOut,
        FileState.adapting => Curves.easeInOut,
        FileState.actNow => const _BouncyJelly(),
        FileState.failed => const _ElasticSnap(),
        FileState.recovered => Curves.easeOut,
      };
}

/// FLUBBER bouncy_jelly: cubic-bezier(0.175, 0.885, 0.32, 1.275)
class _BouncyJelly extends Curve {
  const _BouncyJelly();

  @override
  double transformInternal(double t) {
    final p = t - 1;
    return 1 + p * p * (2.275 * p + 1.275);
  }
}

/// FLUBBER elastic_snap: cubic-bezier(0.68, -0.55, 0.265, 1.55)
class _ElasticSnap extends Curve {
  const _ElasticSnap();

  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      return 2 * t * t * (3.5 * t - 0.55);
    }
    final p = 2 * t - 2;
    return 0.5 * (p * p * (3.5 * p + 0.55) + 2);
  }
}
