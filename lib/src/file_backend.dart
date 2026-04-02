import 'dart:convert';
import 'dart:io';

import 'storage_backend.dart';

/// File-based storage backend using a JSON file on disk.
///
/// Suitable for CLI tools, server apps, and desktop apps.
class FileBackend implements StorageBackend {
  final String path;
  Map<String, String>? _cache;

  /// Create a file backend storing data at [path].
  FileBackend(this.path);

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      _cache = Map<String, String>.from(
        json.decode(content) as Map<String, dynamic>,
      );
    } else {
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _save() async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(json.encode(_cache));
  }

  @override
  Future<String?> read(String key) async {
    final data = await _load();
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    final data = await _load();
    data[key] = value;
    await _save();
  }

  @override
  Future<bool> delete(String key) async {
    final data = await _load();
    final existed = data.remove(key) != null;
    if (existed) await _save();
    return existed;
  }

  @override
  Future<bool> containsKey(String key) async {
    final data = await _load();
    return data.containsKey(key);
  }

  @override
  Future<List<String>> allKeys() async {
    final data = await _load();
    return data.keys.toList();
  }

  @override
  Future<void> clear() async {
    _cache = {};
    await _save();
  }
}
