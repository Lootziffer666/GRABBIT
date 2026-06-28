# GRABBIT

**Android-Dateimanager für Leute, die nicht Ordner verwalten wollen, sondern Arbeitsreste wiederfinden, markieren, bündeln und weiterverwenden müssen.**

Immer neueste Dateien zuerst. Everything-Prinzip: einmal Index aufbauen, nur noch inkrementell updaten, alles ohne Wartezeit auffindbar. FLUBBER Design System. GPL-3.

---

## Architektur

```
grabbit/
├── grabbit_core/              ← Pure Dart engine (kein Flutter)
│   └── lib/src/
│       ├── indexed_file.dart  — Universeller Datei-Datensatz
│       ├── file_query.dart    — Query-Deskriptoren (Recent, Search, Folder)
│       ├── file_action.dart   — Aktionen + Copy-Semantik
│       ├── file_source.dart   — "Wo kommt die Datei her?"
│       ├── file_state.dart    — Lifecycle (Stable/Adapting/ActNow/Failed/Recovered)
│       └── index_schema.dart  — SQLite + FTS5 Schema
├── lib/
│   ├── main.dart
│   ├── animations/            ← KYUUBI Motion Grammar (portiert)
│   │   ├── border_beam.dart
│   │   ├── gooey_button.dart
│   │   ├── scroll_reveal.dart
│   │   ├── press_ripple.dart
│   │   ├── luminous_energy_line.dart
│   │   └── orbital_dot_loader.dart
│   ├── theme/
│   │   ├── grabbit_colors.dart      — FLUBBER-Palette (dark-matte)
│   │   ├── grabbit_theme.dart       — ThemeData
│   │   └── grabbit_design_bridge.dart — FileType/State → Token Mapping
│   ├── screens/
│   │   └── recent_screen.dart       — Startscreen (neueste Dateien zuerst)
│   └── widgets/
│       ├── file_card.dart           — Universelle Datei-Karte
│       ├── category_chip.dart       — Filter-Chips
│       └── search_bar_widget.dart   — Instant-Suche
└── android/
    └── .../GrabbitIndexChannel.kt   — Platform Channel Skeleton (MediaStore, SAF)
```

## Design System

Built on [FLUBBER](https://github.com/lootziffer666/FLUBBER) — the same
elastic/liquid motion grammar used in [KYUUBI](https://github.com/lootziffer666/KYUUBI)
and [APP-LAB](https://github.com/lootziffer666/APP-LAB).

## Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter |
| State | Riverpod |
| Navigation | go_router |
| DB / Index | sqflite + FTS5 |
| Animations | KYUUBI Motion Grammar + Lottie |
| Fonts | Lilita One, Barlow, JetBrains Mono |
| Platform Bridge | MethodChannel → Kotlin (MediaStore, FileObserver, SAF) |
| OCR (later) | google_mlkit_text_recognition |
| Smart Analysis (later) | ONNX Runtime Mobile |

## The "Everything" Principle

Standard file managers do a live filesystem read on every folder change:
- 5,000 files in a folder → seconds of waiting
- Search = recursive walk → minutes
- Downloads with 2,000 files → UI freezes

GRABBIT with index:
- 5,000 files in a folder → 2ms DB query, instantly rendered
- Search over everything → FTS5, <5ms regardless of file count
- "Newest 50 files" → one query, no in-memory sorting

## Getting Started

```bash
flutter pub get
flutter run
```

## License

GPL-3.0 — see [LICENSE](LICENSE).
