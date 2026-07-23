import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grabbit/services/clipboard_service.dart';

void main() {
  group('ClipboardService.splitIntoPassages', () {
    test('keeps short text in one passage', () {
      expect(
        ClipboardService.splitIntoPassages('kurzer Text', maxBytes: 20),
        ['kurzer Text'],
      );
    });

    test('reconstructs long text exactly and respects UTF-8 byte limit', () {
      final source = List.filled(80, 'Grüße 👋\n').join();
      final passages = ClipboardService.splitIntoPassages(
        source,
        maxBytes: 37,
      );

      expect(passages.length, greaterThan(1));
      expect(passages.join(), source);
      for (final passage in passages) {
        expect(utf8.encode(passage).length, lessThanOrEqualTo(37));
      }
    });

    test('does not split surrogate pairs', () {
      final passages = ClipboardService.splitIntoPassages(
        '😀😀😀',
        maxBytes: 4,
      );

      expect(passages, ['😀', '😀', '😀']);
    });

    test('returns no passage for empty content', () {
      expect(ClipboardService.splitIntoPassages(''), isEmpty);
    });
  });
}
