/// Known file sources — "where did this file come from?"
/// Used for smart filtering and the Arbeitsstrom concept.
enum FileSource {
  camera,
  screenshot,
  download,
  whatsapp,
  telegram,
  chatgpt,
  browser,
  bluetooth,
  email,
  recording,
  appExport,
  unknown;

  /// Attempt to guess source from file path.
  static FileSource fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('/dcim/') || lower.contains('/camera/')) return camera;
    if (lower.contains('screenshot')) return screenshot;
    if (lower.contains('/download')) return download;
    if (lower.contains('whatsapp')) return whatsapp;
    if (lower.contains('telegram')) return telegram;
    if (lower.contains('chatgpt') || lower.contains('openai')) return chatgpt;
    if (lower.contains('bluetooth')) return bluetooth;
    if (lower.contains('/recording')) return recording;
    return unknown;
  }

  String get label => switch (this) {
        camera => 'Kamera',
        screenshot => 'Screenshot',
        download => 'Download',
        whatsapp => 'WhatsApp',
        telegram => 'Telegram',
        chatgpt => 'ChatGPT',
        browser => 'Browser',
        bluetooth => 'Bluetooth',
        email => 'E-Mail',
        recording => 'Aufnahme',
        appExport => 'App-Export',
        unknown => 'Unbekannt',
      };
}
