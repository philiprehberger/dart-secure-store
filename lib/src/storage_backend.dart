/// Abstract interface for storage backends.
///
/// Implement this to create custom backends (e.g., SharedPreferences, Hive, SQLite).
abstract class StorageBackend {
  /// Read a value by key. Returns null if not found.
  Future<String?> read(String key);

  /// Write a key-value pair.
  Future<void> write(String key, String value);

  /// Delete a key. Returns true if the key existed.
  Future<bool> delete(String key);

  /// Check if a key exists.
  Future<bool> containsKey(String key);

  /// Get all stored keys.
  Future<List<String>> allKeys();

  /// Delete all stored data.
  Future<void> clear();
}
