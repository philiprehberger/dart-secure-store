import 'dart:convert';

/// Internal wrapper for TTL-enabled storage entries.
class ExpirableEntry {
  final String value;
  final DateTime? expiresAt;

  const ExpirableEntry({required this.value, this.expiresAt});

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String encode() => jsonEncode({'value': value, 'expiresAt': expiresAt?.toIso8601String()});

  static ExpirableEntry? decode(String encoded) {
    try {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      return ExpirableEntry(
        value: map['value'] as String,
        expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt'] as String) : null,
      );
    } catch (_) {
      return null;
    }
  }
}
