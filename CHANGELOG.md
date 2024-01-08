# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
