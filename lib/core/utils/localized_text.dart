import 'dart:convert';

/// Duma stores many catalog fields (category names, product titles and
/// descriptions) as a JSON-encoded map of translations, e.g.
/// `{"fr":"Boissons","en":"Drinks","es":"...","sw":"..."}` instead of a
/// plain string. This mirrors the extraction logic used by the official app
/// (`dashboard_wrapper.dart#_extractTranslatedText`) so Eureka renders the
/// human-readable label instead of the raw JSON blob.
abstract final class LocalizedText {
  static const List<String> _preferredOrder = ['fr', 'en', 'es', 'sw'];

  static String extract(dynamic raw, {String fallback = ''}) {
    if (raw == null) return fallback;
    final text = raw.toString();
    if (text.isEmpty) return fallback;

    final looksLikeJson = text.trimLeft().startsWith('{');
    if (!looksLikeJson) return text;

    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return text;
      final map = decoded.cast<String, dynamic>();

      for (final lang in _preferredOrder) {
        final value = map[lang];
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
      for (final value in map.values) {
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
      return fallback;
    } catch (_) {
      return text;
    }
  }
}
