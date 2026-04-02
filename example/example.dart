// ignore_for_file: unused_local_variable

import 'package:philiprehberger_secure_store/secure_store.dart';
import 'package:philiprehberger_secure_store/file_backend.dart';

Future<void> main() async {
  // Create a secure store with an encryption key
  final store = SecureStore(encryptionKey: 'my-secret-key-256');

  // Store and retrieve a string
  await store.write('api_token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
  final token = await store.read('api_token');
  print('Token: $token');

  // Store and retrieve JSON
  await store.writeJson('user', {
    'name': 'Alice',
    'email': 'alice@example.com',
    'role': 'admin',
  });
  final user = await store.readJson('user');
  print('User: ${user!['name']}');

  // Store typed values
  await store.writeBool('dark_mode', true);
  await store.writeInt('login_count', 42);

  final darkMode = await store.readBool('dark_mode');
  final count = await store.readInt('login_count');
  print('Dark mode: $darkMode, Logins: $count');

  // Key management
  final keys = await store.allKeys();
  print('Stored keys: $keys');

  final exists = await store.containsKey('api_token');
  print('Has token: $exists');

  // Delete a single key
  await store.delete('api_token');

  // Clear everything
  await store.clear();

  // Use a file backend for persistence
  final persistentStore = SecureStore(
    encryptionKey: 'my-key',
    backend: FileBackend('/tmp/secure_store_example.json'),
  );
  await persistentStore.write('session', 'abc123');
  final session = await persistentStore.read('session');
  print('Session: $session');

  // Strict access — throws if key is missing
  try {
    await store.readOrThrow('nonexistent');
  } on KeyNotFoundError catch (e) {
    print('Expected error: $e');
  }
}
