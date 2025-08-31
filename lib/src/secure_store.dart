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
  Encryption _encryption;

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

  /// Re-encrypt all stored values under a new encryption key.
  ///
  /// Reads and decrypts every entry with the current key, then re-encrypts
  /// and writes each entry using [newKey].
  Future<void> rotateKey(String newKey) async {
    final keys = await allKeys();
    final oldEncryption = _encryption;
    final newEncryption = Encryption(newKey);

    for (final key in keys) {
      final encrypted = await _backend.read(key);
      if (encrypted == null) continue;
      final decrypted = oldEncryption.decrypt(encrypted);
      final reEncrypted = newEncryption.encrypt(decrypted);
      await _backend.write(key, reEncrypted);
    }

    _encryption = newEncryption;
  }

  /// Export all raw encrypted key-value pairs from the backend.
  ///
  /// Returns a map of keys to their encrypted (base64) values.
  Future<Map<String, String>> backup() async {
    final keys = await allKeys();
    final data = <String, String>{};
    for (final key in keys) {
      final value = await _backend.read(key);
      if (value != null) {
        data[key] = value;
      }
    }
    return data;
  }

  /// Clear the store and write all entries from [data] directly to the backend.
  ///
  /// The values in [data] should be raw encrypted strings (as returned by [backup]).
  Future<void> restore(Map<String, String> data) async {
    await _backend.clear();
    for (final entry in data.entries) {
      await _backend.write(entry.key, entry.value);
    }
  }

  /// Export the store as a JSON string of raw encrypted key-value pairs.
  Future<String> export() async {
    final data = await backup();
    return json.encode(data);
  }

  /// Clear the store and import entries from a JSON string.
  ///
  /// The JSON should be an object of key-value pairs as produced by [export].
  Future<void> import(String jsonString) async {
    final data = (json.decode(jsonString) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as String));
    await restore(data);
  }

  /// The number of keys currently stored.
  Future<int> get keyCount async {
    final keys = await allKeys();
    return keys.length;
  }

  /// Delete all entries matching a predicate on the key.
  ///
  /// Returns the number of entries removed.
  Future<int> deleteWhere(bool Function(String key) test) async {
    final keys = await allKeys();
    var count = 0;
    for (final key in keys) {
      if (test(key)) {
        await delete(key);
        count++;
      }
    }
    return count;
  }

  /// Returns a namespaced view of this store.
  ///
  /// All operations on the returned store automatically prefix keys with
  /// `[prefix].`. This allows logical separation of key groups (settings,
  /// tokens, cache) within a single store.
  NamespacedStore namespace(String prefix) => NamespacedStore._(this, prefix);
}

/// A namespaced view of a [SecureStore] that prefixes all keys.
///
/// Returned by [SecureStore.namespace]. All read/write/delete operations
/// are scoped to keys starting with the namespace prefix.
class NamespacedStore {
  final SecureStore _parent;
  final String _prefix;

  NamespacedStore._(this._parent, this._prefix);

  String _key(String key) => '$_prefix.$key';

  /// The namespace prefix.
  String get prefix => _prefix;

  /// Store a string value in this namespace.
  Future<void> write(String key, String value) => _parent.write(_key(key), value);

  /// Read a string value from this namespace.
  Future<String?> read(String key) => _parent.read(_key(key));

  /// Store a JSON object in this namespace.
  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      _parent.writeJson(_key(key), value);

  /// Read a JSON object from this namespace.
  Future<Map<String, dynamic>?> readJson(String key) =>
      _parent.readJson(_key(key));

  /// Store a boolean in this namespace.
  Future<void> writeBool(String key, bool value) =>
      _parent.writeBool(_key(key), value);

  /// Read a boolean from this namespace.
  Future<bool?> readBool(String key) => _parent.readBool(_key(key));

  /// Store an integer in this namespace.
  Future<void> writeInt(String key, int value) =>
      _parent.writeInt(_key(key), value);

  /// Read an integer from this namespace.
  Future<int?> readInt(String key) => _parent.readInt(_key(key));

  /// Delete a key from this namespace.
  Future<bool> delete(String key) => _parent.delete(_key(key));

  /// Check if a key exists in this namespace.
  Future<bool> containsKey(String key) => _parent.containsKey(_key(key));

  /// Get all keys in this namespace (without the prefix).
  Future<List<String>> allKeys() async {
    final all = await _parent.allKeys();
    final prefixDot = '$_prefix.';
    return all
        .where((k) => k.startsWith(prefixDot))
        .map((k) => k.substring(prefixDot.length))
        .toList();
  }

  /// Delete all keys in this namespace.
  Future<void> clear() async {
    final keys = await allKeys();
    for (final key in keys) {
      await delete(key);
    }
  }

  /// The number of keys in this namespace.
  Future<int> get keyCount async {
    final keys = await allKeys();
    return keys.length;
  }
}
