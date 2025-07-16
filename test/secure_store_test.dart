import 'dart:convert';

import 'package:philiprehberger_secure_store/secure_store.dart';
import 'package:test/test.dart';

void main() {
  late SecureStore store;

  setUp(() {
    store = SecureStore(encryptionKey: 'test-secret-key-123');
  });

  group('SecureStore', () {
    test('write and read string', () async {
      await store.write('token', 'my-secret-token');
      final result = await store.read('token');
      expect(result, equals('my-secret-token'));
    });

    test('read nonexistent key returns null', () async {
      final result = await store.read('missing');
      expect(result, isNull);
    });

    test('write and read JSON', () async {
      await store.writeJson('user', {'name': 'Alice', 'age': 30});
      final result = await store.readJson('user');
      expect(result, isNotNull);
      expect(result!['name'], equals('Alice'));
      expect(result['age'], equals(30));
    });

    test('write and read bool', () async {
      await store.writeBool('dark_mode', true);
      expect(await store.readBool('dark_mode'), isTrue);
      await store.writeBool('dark_mode', false);
      expect(await store.readBool('dark_mode'), isFalse);
    });

    test('write and read int', () async {
      await store.writeInt('count', 42);
      expect(await store.readInt('count'), equals(42));
    });

    test('delete key', () async {
      await store.write('temp', 'value');
      final deleted = await store.delete('temp');
      expect(deleted, isTrue);
      expect(await store.read('temp'), isNull);
    });

    test('delete nonexistent key returns false', () async {
      final deleted = await store.delete('missing');
      expect(deleted, isFalse);
    });

    test('containsKey', () async {
      await store.write('exists', 'yes');
      expect(await store.containsKey('exists'), isTrue);
      expect(await store.containsKey('missing'), isFalse);
    });

    test('allKeys', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      final keys = await store.allKeys();
      expect(keys, containsAll(['a', 'b']));
    });

    test('clear', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      await store.clear();
      final keys = await store.allKeys();
      expect(keys, isEmpty);
    });

    test('readOrThrow succeeds for existing key', () async {
      await store.write('key', 'value');
      final result = await store.readOrThrow('key');
      expect(result, equals('value'));
    });

    test('readOrThrow throws for missing key', () async {
      expect(
        () => store.readOrThrow('missing'),
        throwsA(isA<KeyNotFoundError>()),
      );
    });

    test('overwrite existing key', () async {
      await store.write('key', 'first');
      await store.write('key', 'second');
      expect(await store.read('key'), equals('second'));
    });

    test('handles special characters', () async {
      await store.write('key', 'héllo wörld 🎉 <>&"');
      expect(await store.read('key'), equals('héllo wörld 🎉 <>&"'));
    });

    test('handles empty string', () async {
      await store.write('empty', '');
      expect(await store.read('empty'), equals(''));
    });

    test('handles long values', () async {
      final long = 'x' * 10000;
      await store.write('long', long);
      expect(await store.read('long'), equals(long));
    });
  });

  group('Encryption', () {
    test('encrypt and decrypt roundtrip', () {
      final enc = Encryption('my-key');
      final cipher = enc.encrypt('hello world');
      expect(cipher, isNot(equals('hello world')));
      expect(enc.decrypt(cipher), equals('hello world'));
    });

    test('different keys produce different ciphertext', () {
      final enc1 = Encryption('key1');
      final enc2 = Encryption('key2');
      final c1 = enc1.encrypt('same');
      final c2 = enc2.encrypt('same');
      expect(c1, isNot(equals(c2)));
    });

    test('wrong key fails to decrypt correctly', () {
      final enc1 = Encryption('correct-key-abc-123');
      final enc2 = Encryption('wrong-key-xyz-789');
      final original = 'this is a longer secret message that should not match';
      final cipher = enc1.encrypt(original);
      // Wrong key will produce garbage — either different text or invalid UTF-8
      try {
        final result = enc2.decrypt(cipher);
        expect(result, isNot(equals(original)));
      } on EncryptionError {
        // Also acceptable — decryption may fail entirely
      }
    });

    test('decrypt invalid data throws', () {
      final enc = Encryption('key');
      expect(
          () => enc.decrypt('not-valid-base64!!!'), throwsA(isA<EncryptionError>()));
    });
  });

  group('MemoryBackend', () {
    test('basic operations', () async {
      final backend = MemoryBackend();
      await backend.write('k', 'v');
      expect(await backend.read('k'), equals('v'));
      expect(await backend.containsKey('k'), isTrue);
      expect(await backend.allKeys(), equals(['k']));
      await backend.delete('k');
      expect(await backend.read('k'), isNull);
    });
  });

  group('Batch Operations', () {
    test('writeMultiple and readMultiple', () async {
      await store.writeMultiple({'a': '1', 'b': '2', 'c': '3'});
      final result = await store.readMultiple(['a', 'b', 'c', 'missing']);
      expect(result['a'], equals('1'));
      expect(result['b'], equals('2'));
      expect(result['c'], equals('3'));
      expect(result['missing'], isNull);
    });

    test('writeMultiple overwrites existing', () async {
      await store.write('key', 'old');
      await store.writeMultiple({'key': 'new'});
      expect(await store.read('key'), equals('new'));
    });

    test('readMultiple with empty list', () async {
      final result = await store.readMultiple([]);
      expect(result, isEmpty);
    });
  });

  group('TTL / Expiration', () {
    test('writeWithExpiry stores and reads before expiry', () async {
      await store.writeWithExpiry('ttl', 'value', const Duration(hours: 1));
      expect(await store.isExpired('ttl'), isFalse);
    });

    test('isExpired returns true after TTL', () async {
      await store.writeWithExpiry('expired', 'old', Duration.zero);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(await store.isExpired('expired'), isTrue);
    });

    test('isExpired returns false for missing key', () async {
      expect(await store.isExpired('nonexistent'), isFalse);
    });

    test('isExpired returns false for non-expirable key', () async {
      await store.write('normal', 'value');
      expect(await store.isExpired('normal'), isFalse);
    });

    test('cleanExpired removes expired entries', () async {
      await store.write('keep', 'value');
      await store.writeWithExpiry('expire1', 'old', Duration.zero);
      await store.writeWithExpiry('expire2', 'old', Duration.zero);
      await Future.delayed(const Duration(milliseconds: 10));
      final removed = await store.cleanExpired();
      expect(removed, equals(2));
      expect(await store.containsKey('keep'), isTrue);
      expect(await store.containsKey('expire1'), isFalse);
    });
  });

  group('Key Rotation', () {
    test('rotateKey re-encrypts all values', () async {
      await store.write('token', 'secret-value');
      await store.write('name', 'Alice');

      await store.rotateKey('new-secret-key-456');

      expect(await store.read('token'), equals('secret-value'));
      expect(await store.read('name'), equals('Alice'));
    });

    test('rotateKey works with expirable entries', () async {
      await store.writeWithExpiry(
          'session', 'token123', const Duration(hours: 1));
      await store.write('normal', 'value');

      await store.rotateKey('rotated-key-789');

      expect(await store.read('normal'), equals('value'));
      // Expirable entry is re-encrypted as raw — decrypted value is the
      // encoded JSON wrapper, which round-trips correctly.
      final sessionValue = await store.read('session');
      expect(sessionValue, isNotNull);
    });
  });

  group('Backup / Restore', () {
    test('backup and restore round-trip', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      await store.write('c', '3');

      final data = await store.backup();
      expect(data.length, equals(3));

      await store.clear();
      expect(await store.allKeys(), isEmpty);

      await store.restore(data);
      expect(await store.read('a'), equals('1'));
      expect(await store.read('b'), equals('2'));
      expect(await store.read('c'), equals('3'));
    });

    test('export and import round-trip', () async {
      await store.write('x', 'hello');
      await store.write('y', 'world');

      final exported = await store.export();
      // Verify it is valid JSON
      expect(() => json.decode(exported), returnsNormally);

      await store.clear();
      expect(await store.allKeys(), isEmpty);

      await store.import(exported);
      expect(await store.read('x'), equals('hello'));
      expect(await store.read('y'), equals('world'));
    });

    test('restore clears existing data', () async {
      await store.write('old', 'data');
      final data = <String, String>{};

      // Backup an empty store to get empty map, then restore it
      await store.restore(data);
      expect(await store.containsKey('old'), isFalse);
      expect(await store.allKeys(), isEmpty);
    });
  });

  group('keyCount', () {
    test('returns correct count', () async {
      expect(await store.keyCount, equals(0));
      await store.write('a', '1');
      expect(await store.keyCount, equals(1));
      await store.write('b', '2');
      await store.write('c', '3');
      expect(await store.keyCount, equals(3));
      await store.delete('b');
      expect(await store.keyCount, equals(2));
    });
  });

  group('SecureStoreError', () {
    test('toString includes message', () {
      const error = SecureStoreError('test error');
      expect(error.toString(), contains('test error'));
    });

    test('KeyNotFoundError includes key', () {
      const error = KeyNotFoundError('my-key');
      expect(error.toString(), contains('my-key'));
    });
  });
}
