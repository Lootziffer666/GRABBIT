import 'package:flutter/material.dart';

/// FLUBBER-derived color palette for GRABBIT.
/// Same token structure as KYUUBI/The Forge — visual continuity across projects.
abstract final class GrabbitColors {
  // ── Dark backgrounds (KYUUBI-style matte workbench) ──────────────────────
  static const Color void_ = Color(0xFF141416);
  static const Color surface = Color(0xFF1E1E21);
  static const Color card = Color(0xFF252528);
  static const Color raised = Color(0xFF2E2E32);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border = Color(0x12FFFFFF); // 7%
  static const Color borderStrong = Color(0x24FFFFFF); // 14%

  // ── Semantic / State colors (GRABBIT FileState mapping) ──────────────────
  static const Color stable = Color(0xFF3DAA6A); // green — all good
  static const Color adapting = Color(0xFF1DB8AC); // turquoise — needs attention
  static const Color actNow = Color(0xFFF5821F); // orange — user must decide
  static const Color failed = Color(0xFFD94040); // red — action blocked
  static const Color recovered = Color(0xFF8B9FE8); // periwinkle — restored

  // ── File category colors ─────────────────────────────────────────────────
  static const Color image = Color(0xFF1DB8AC); // turquoise
  static const Color video = Color(0xFFA855F7); // violet
  static const Color audio = Color(0xFFFF6EB4); // pink
  static const Color document = Color(0xFFF5821F); // orange
  static const Color archive = Color(0xFFD4A827); // yellow/gold
  static const Color code = Color(0xFF3EC4D0); // cyan
  static const Color app = Color(0xFF7ED321); // lime
  static const Color other = Color(0xFFCBD5E1); // muted

  // ── FLUBBER accent palette ───────────────────────────────────────────────
  static const Color turquoise = Color(0xFF1DB8AC);
  static const Color orange = Color(0xFFF5821F);
  static const Color green = Color(0xFF3DAA6A);
  static const Color red = Color(0xFFD94040);
  static const Color yellow = Color(0xFFD4A827);
  static const Color periwinkle = Color(0xFF8B9FE8);
  static const Color violet = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF3EC4D0);
  static const Color coral = Color(0xFFFF5757);
  static const Color lime = Color(0xFF7ED321);
  static const Color pink = Color(0xFFFF6EB4);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color t1 = Color(0xFFF2F2F2); // primary text
  static const Color t2 = Color(0x9EF2F2F2); // 62% — secondary
  static const Color t3 = Color(0x61F2F2F2); // 38% — tertiary
  static const Color t4 = Color(0x2EF2F2F2); // 18% — hint

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1C1B2E);
  static const Color muted = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFF1F2937);
  static const Color inputFill = Color(0xFF1F2937);
}
