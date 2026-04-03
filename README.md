# philiprehberger_secure_store

[![Tests](https://github.com/philiprehberger/dart-secure-store/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-secure-store/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_secure_store.svg)](https://pub.dev/packages/philiprehberger_secure_store)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-secure-store)](https://github.com/philiprehberger/dart-secure-store/commits/main)

Unified secure storage with built-in encryption and pluggable backends

## Requirements

- Dart >= 3.5

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_secure_store: ^0.3.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_secure_store/secure_store.dart';

final store = SecureStore(encryptionKey: 'my-secret-key');
await store.write('token', 'eyJhbGciOiJIUzI1...');
final token = await store.read('token');
```

### JSON Storage

```dart
await store.writeJson('user', {'name': 'Alice', 'role': 'admin'});
final user = await store.readJson('user');
print(user!['name']); // Alice
```

### Typed Values

```dart
await store.writeBool('dark_mode', true);
await store.writeInt('login_count', 42);

final darkMode = await store.readBool('dark_mode'); // true
final count = await store.readInt('login_count'); // 42
```

### File Backend (Persistent)

For non-web platforms, import the file backend separately:

```dart
import 'package:philiprehberger_secure_store/secure_store.dart';
import 'package:philiprehberger_secure_store/file_backend.dart';

final store = SecureStore(
  encryptionKey: 'my-key',
  backend: FileBackend('/path/to/storage.json'),
);
await store.write('token', 'secret');
// Data persists across restarts
```

### Custom Backend

Implement `StorageBackend` for any storage system:

```dart
class MyDatabaseBackend implements StorageBackend {
  @override
  Future<String?> read(String key) async { /* ... */ }
  @override
  Future<void> write(String key, String value) async { /* ... */ }
  // ... implement all methods
}

final store = SecureStore(
  encryptionKey: 'key',
  backend: MyDatabaseBackend(),
);
```

### Batch Operations

```dart
await store.writeMultiple({'token': 'abc', 'refresh': 'xyz', 'user': 'alice'});
final results = await store.readMultiple(['token', 'refresh']);
// {'token': 'abc', 'refresh': 'xyz'}
```

### Expiration / TTL

```dart
await store.writeWithExpiry('session', 'token123', Duration(hours: 1));
await store.isExpired('session');  // false

// Clean up all expired entries
final removed = await store.cleanExpired();
```

### Key Management

```dart
await store.containsKey('token'); // true
await store.allKeys(); // ['token', 'user', ...]
await store.delete('token');
await store.clear(); // remove everything

// Strict access — throws if key missing
final value = await store.readOrThrow('token');

// Quick key count
final count = await store.keyCount;
```

### Key Rotation

Re-encrypt all stored values under a new encryption key:

```dart
await store.rotateKey('new-secret-key');
// All existing values are now encrypted with the new key
```

### Backup & Restore

```dart
// Export raw encrypted data
final data = await store.backup();

// Restore from backup (clears store first)
await store.restore(data);

// JSON-based export/import
final jsonStr = await store.export();
await store.import(jsonStr);
```

## API

### `SecureStore`

| Method | Description |
|--------|-------------|
| `SecureStore(encryptionKey:, backend:)` | Create with encryption key and optional backend |
| `.write(key, value)` | Store an encrypted string |
| `.read(key)` | Read and decrypt a string (null if missing) |
| `.writeJson(key, value)` | Store an encrypted JSON object |
| `.readJson(key)` | Read and decrypt a JSON object |
| `.writeBool(key, value)` | Store an encrypted boolean |
| `.readBool(key)` | Read a boolean |
| `.writeInt(key, value)` | Store an encrypted integer |
| `.readInt(key)` | Read an integer |
| `.delete(key)` | Delete a key |
| `.containsKey(key)` | Check if a key exists |
| `.allKeys()` | List all stored keys |
| `.clear()` | Delete all data |
| `.readOrThrow(key)` | Read or throw `KeyNotFoundError` |
| `.writeMultiple(pairs)` | Write multiple key-value pairs |
| `.readMultiple(keys)` | Read multiple keys at once |
| `.writeWithExpiry(key, value, ttl)` | Store with time-to-live |
| `.isExpired(key)` | Check if an item has expired |
| `.cleanExpired()` | Remove all expired items |
| `.rotateKey(newKey)` | Re-encrypt all values with a new key |
| `.backup()` | Export raw encrypted key-value pairs |
| `.restore(data)` | Clear and restore from raw encrypted data |
| `.export()` | Export store as a JSON string |
| `.import(json)` | Clear and import from a JSON string |
| `.keyCount` | Get the number of stored keys |

### Backends

| Backend | Description |
|---------|-------------|
| `MemoryBackend` | In-memory (default, for testing) |
| `FileBackend(path)` | JSON file on disk |
| `StorageBackend` | Abstract interface for custom backends |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

- [Star the repo](https://github.com/philiprehberger/dart-secure-store)
- [Report issues](https://github.com/philiprehberger/dart-secure-store/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
- [Suggest features](https://github.com/philiprehberger/dart-secure-store/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
- [Sponsor development](https://github.com/sponsors/philiprehberger)
- [All Open Source Projects](https://philiprehberger.com/open-source-packages)
- [GitHub Profile](https://github.com/philiprehberger)
- [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
