import 'dart:convert';

import 'encryption.dart';
import 'expirable_entry.dart';
import 'memory_backend.dart';
import 'secure_store_error.dart';
import 'storage_backend.dart';

/// Unified secure storage with built-in encryption and pluggable backends.
///
/// All values are encrypted before storage and decrypted on retrieval.
class SecureStore {
  final StorageBackend _backend;
  final Encryption _encryption;

  /// Create a secure store with encryption key and optional backend.
  ///
  /// Defaults to [MemoryBackend] if no backend is provided.
  SecureStore({
    required String encryptionKey,
    StorageBackend? backend,
  })  : _backend = backend ?? MemoryBackend(),
        _encryption = Encryption(encryptionKey);

  /// Store a string value securely.
  Future<void> write(String key, String value) async {
    final encrypted = _encryption.encrypt(value);
    await _backend.write(key, encrypted);
  }

  /// Retrieve and decrypt a string value.
  ///
  /// Returns null if the key does not exist.
  Future<String?> read(String key) async {
    final encrypted = await _backend.read(key);
    if (encrypted == null) return null;
    return _encryption.decrypt(encrypted);
  }

  /// Store a JSON-serializable object.
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await write(key, json.encode(value));
  }

  /// Retrieve and decode a JSON object.
  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = await read(key);
    if (value == null) return null;
    return json.decode(value) as Map<String, dynamic>;
  }

  /// Store a boolean value.
  Future<void> writeBool(String key, bool value) async {
    await write(key, value.toString());
  }

  /// Retrieve a boolean value.
  Future<bool?> readBool(String key) async {
    final value = await read(key);
    if (value == null) return null;
    return value == 'true';
  }

  /// Store an integer value.
  Future<void> writeInt(String key, int value) async {
    await write(key, value.toString());
  }

  /// Retrieve an integer value.
  Future<int?> readInt(String key) async {
    final value = await read(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Delete a key. Returns true if the key existed.
  Future<bool> delete(String key) async {
    return _backend.delete(key);
  }

  /// Check if a key exists.
  Future<bool> containsKey(String key) async {
    return _backend.containsKey(key);
  }

  /// Get all stored keys.
  Future<List<String>> allKeys() async {
    return _backend.allKeys();
  }

  /// Delete all stored data.
  Future<void> clear() async {
    await _backend.clear();
  }

  /// Read a value or throw [KeyNotFoundError].
  Future<String> readOrThrow(String key) async {
    final value = await read(key);
    if (value == null) throw KeyNotFoundError(key);
    return value;
  }

  /// Write multiple key-value pairs atomically.
  Future<void> writeMultiple(Map<String, String> pairs) async {
    for (final entry in pairs.entries) {
      await write(entry.key, entry.value);
    }
  }

  /// Read multiple keys at once.
  ///
  /// Returns a map with null values for missing keys.
  Future<Map<String, String?>> readMultiple(List<String> keys) async {
    final results = <String, String?>{};
    for (final key in keys) {
      results[key] = await read(key);
    }
    return results;
  }

  /// Store a value with a time-to-live.
  ///
  /// The value expires after [ttl] and can be cleaned up with [cleanExpired].
  Future<void> writeWithExpiry(String key, String value, Duration ttl) async {
    final entry = ExpirableEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    final encrypted = _encryption.encrypt(entry.encode());
    await _backend.write(key, encrypted);
  }

  /// Check if a stored item has expired.
  ///
  /// Returns false if the key does not exist or was not stored with expiry.
  Future<bool> isExpired(String key) async {
    final encrypted = await _backend.read(key);
    if (encrypted == null) return false;
    final decrypted = _encryption.decrypt(encrypted);
    final entry = ExpirableEntry.decode(decrypted);
    if (entry == null) return false;
    return entry.isExpired;
  }

  /// Remove all expired items.
  ///
  /// Returns the number of items removed.
  Future<int> cleanExpired() async {
    final keys = await allKeys();
    var removed = 0;
    for (final key in keys) {
      if (await isExpired(key)) {
        await delete(key);
        removed++;
      }
    }
    return removed;
  }
}
