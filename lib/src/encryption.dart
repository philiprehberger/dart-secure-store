import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'secure_store_error.dart';

/// Encryption utility using XOR with a key-derived pseudorandom pad.
///
/// Uses a simple PRNG seeded from the key for local storage obfuscation.
/// For high-security needs, integrate a dedicated crypto library.
class Encryption {
  final List<int> _keyBytes;

  /// Create an encryption instance from a secret key string.
  Encryption(String key) : _keyBytes = utf8.encode(key);

  /// Encrypt plaintext and return a base64-encoded ciphertext.
  String encrypt(String plaintext) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final plainBytes = utf8.encode(plaintext);
    final pad = _generatePad(salt, plainBytes.length);
    final cipher = Uint8List(plainBytes.length);
    for (var i = 0; i < plainBytes.length; i++) {
      cipher[i] = plainBytes[i] ^ pad[i];
    }
    final combined = Uint8List(salt.length + cipher.length);
    combined.setAll(0, salt);
    combined.setAll(salt.length, cipher);
    return base64Encode(combined);
  }

  /// Decrypt a base64-encoded ciphertext back to plaintext.
  String decrypt(String ciphertext) {
    try {
      final combined = base64Decode(ciphertext);
      if (combined.length < 16) {
        throw const EncryptionError('Invalid ciphertext');
      }
      final salt = combined.sublist(0, 16);
      final cipher = combined.sublist(16);
      final pad = _generatePad(salt, cipher.length);
      final plain = Uint8List(cipher.length);
      for (var i = 0; i < cipher.length; i++) {
        plain[i] = cipher[i] ^ pad[i];
      }
      return utf8.decode(plain);
    } catch (e) {
      if (e is EncryptionError) rethrow;
      throw EncryptionError('Decryption failed: $e');
    }
  }

  /// Generate a pseudorandom pad from salt + key using a simple hash-like expansion.
  List<int> _generatePad(List<int> salt, int length) {
    // Simple PRNG: seed from key + salt bytes
    var seed = 0;
    for (final b in [...salt, ..._keyBytes]) {
      seed = (seed * 31 + b) & 0xFFFFFFFF;
    }
    final rng = Random(seed);
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }
}
