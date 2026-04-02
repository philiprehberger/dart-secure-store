import 'storage_backend.dart';

/// In-memory storage backend. Data is lost when the process exits.
///
/// Useful for testing and development.
class MemoryBackend implements StorageBackend {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<bool> delete(String key) async {
    return _store.remove(key) != null;
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<List<String>> allKeys() async => _store.keys.toList();

  @override
  Future<void> clear() async => _store.clear();
}
