/// Base exception for cache-related errors
abstract class CacheException implements Exception {
  final String message;
  final dynamic originalError;
  
  const CacheException(this.message, [this.originalError]);
  
  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when cache initialization fails
class CacheInitializationException extends CacheException {
  const CacheInitializationException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheInitializationException: $message';
}

/// Exception thrown when cache read operations fail
class CacheReadException extends CacheException {
  const CacheReadException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheReadException: $message';
}

/// Exception thrown when cache write operations fail
class CacheWriteException extends CacheException {
  const CacheWriteException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheWriteException: $message';
}

/// Exception thrown when cache deletion operations fail
class CacheDeleteException extends CacheException {
  const CacheDeleteException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheDeleteException: $message';
}

/// Exception thrown when cache is corrupted
class CacheCorruptedException extends CacheException {
  const CacheCorruptedException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheCorruptedException: $message';
}

/// Exception thrown when cache storage is full
class CacheStorageFullException extends CacheException {
  const CacheStorageFullException(super.message, [super.originalError]);
      
  @override
  String toString() => 'CacheStorageFullException: $message';
}