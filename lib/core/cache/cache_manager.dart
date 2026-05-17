import '../error/exceptions.dart';
import 'cache_policy.dart';
import 'memory_cache.dart';
import 'persistent_cache.dart';

/// Orchestrates the triple-layer cache.
///
/// ```
/// Layer 1 – MemoryCache   (in-process LRU)
/// Layer 2 – PersistentCache (Hive)
/// Layer 3 – Network        (fetcher callback)
/// ```
class CacheManager {
  final MemoryCache _memoryCache;
  final PersistentCache _persistentCache;

  CacheManager({
    required MemoryCache memoryCache,
    required PersistentCache persistentCache,
  }) : _memoryCache = memoryCache,
       _persistentCache = persistentCache;

  /// Returns data according to [policy].
  ///
  /// [fetcher] is the network call wrapped in a closure.
  /// [ttl] applies to both L1 and L2 entries.
  Future<T> get<T>({
    required String key,
    required Future<T> Function() fetcher,
    CachePolicy policy = CachePolicy.cacheFirst,
    Duration? ttl,
  }) async {
    switch (policy) {
      case CachePolicy.networkFirst:
        return _networkFirst<T>(key, fetcher, ttl);
      case CachePolicy.cacheFirst:
        return _cacheFirst<T>(key, fetcher, ttl);
      case CachePolicy.cacheOnly:
        return _cacheOnly<T>(key);
      case CachePolicy.networkOnly:
        return fetcher();
    }
  }

  /// Invalidate a key from both caches.
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _persistentCache.remove(key);
  }

  /// Invalidate all keys starting with [prefix].
  Future<void> invalidateByPrefix(String prefix) async {
    _memoryCache.removeByPrefix(prefix);
    await _persistentCache.removeByPrefix(prefix);
  }

  /// Clear everything.
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _persistentCache.clear();
  }

  // ──────────── Private strategies ────────────

  Future<T> _networkFirst<T>(
    String key,
    Future<T> Function() fetcher,
    Duration? ttl,
  ) async {
    try {
      final data = await fetcher();
      _memoryCache.set<T>(key, data, ttl: ttl);
      await _persistentCache.set<T>(key, data, ttl: ttl);
      return data;
    } catch (_) {
      // Fallback to cache on network failure.
      final memoryHit = _memoryCache.get<T>(key);
      if (memoryHit != null) return memoryHit;

      final persistentHit = await _persistentCache.get<T>(key);
      if (persistentHit != null) {
        _memoryCache.set<T>(key, persistentHit, ttl: ttl);
        return persistentHit;
      }
      rethrow;
    }
  }

  Future<T> _cacheFirst<T>(
    String key,
    Future<T> Function() fetcher,
    Duration? ttl,
  ) async {
    // L1
    final memoryHit = _memoryCache.get<T>(key);
    if (memoryHit != null) return memoryHit;

    // L2
    final persistentHit = await _persistentCache.get<T>(key);
    if (persistentHit != null) {
      _memoryCache.set<T>(key, persistentHit, ttl: ttl);
      return persistentHit;
    }

    // L3 – Network
    final data = await fetcher();
    _memoryCache.set<T>(key, data, ttl: ttl);
    await _persistentCache.set<T>(key, data, ttl: ttl);
    return data;
  }

  Future<T> _cacheOnly<T>(String key) async {
    final memoryHit = _memoryCache.get<T>(key);
    if (memoryHit != null) return memoryHit;

    final persistentHit = await _persistentCache.get<T>(key);
    if (persistentHit != null) return persistentHit;

    throw const CacheException(message: 'No cached data available');
  }
}
