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
      final enc1 = Encryption('correct-key');
      final enc2 = Encryption('wrong-key');
      final cipher = enc1.encrypt('secret');
      final result = enc2.decrypt(cipher);
      expect(result, isNot(equals('secret')));
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
