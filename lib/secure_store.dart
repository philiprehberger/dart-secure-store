/// Unified secure storage with built-in encryption and pluggable backends.
///
/// For file-based persistence (non-web), import the file backend separately:
/// ```dart
/// import 'package:philiprehberger_secure_store/file_backend.dart';
/// ```
library;

export 'src/secure_store.dart';
export 'src/storage_backend.dart';
export 'src/memory_backend.dart';
export 'src/encryption.dart';
export 'src/secure_store_error.dart';
