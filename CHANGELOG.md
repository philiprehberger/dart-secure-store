# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-02

### Added
- `rotateKey()` to re-encrypt all stored values under a new encryption key
- `backup()` and `restore()` for exporting and importing raw encrypted data
- `export()` and `import()` for JSON-based store serialization
- `keyCount` getter for quick key counting

## [0.2.0] - 2026-04-02

### Added
- `writeMultiple()` for batch writing multiple key-value pairs
- `readMultiple()` for batch reading multiple keys
- `writeWithExpiry()` for storing values with time-to-live
- `isExpired()` for checking TTL expiration
- `cleanExpired()` for removing all expired entries

## [0.1.0] - 2026-04-02

### Added
- `SecureStore` with encrypted read/write for strings, JSON, bools, and ints
- `StorageBackend` abstract interface for pluggable backends
- `MemoryBackend` for in-memory storage (testing and development)
- `FileBackend` for JSON file-based persistent storage
- `Encryption` with salt-based XOR and key-derived PRNG
- `readOrThrow` for strict key access
- `allKeys`, `containsKey`, `delete`, `clear` operations
- Zero external dependencies
