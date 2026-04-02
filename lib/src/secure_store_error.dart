/// Errors that can occur during secure storage operations.
class SecureStoreError implements Exception {
  final String message;
  const SecureStoreError(this.message);

  @override
  String toString() => 'SecureStoreError: $message';
}

/// Thrown when a requested key is not found.
class KeyNotFoundError extends SecureStoreError {
  const KeyNotFoundError(String key) : super('Key not found: $key');
}

/// Thrown when encryption or decryption fails.
class EncryptionError extends SecureStoreError {
  const EncryptionError(String detail) : super('Encryption error: $detail');
}
