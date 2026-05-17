/// LRU in-memory cache backed by [LinkedHashMap].
///
/// - O(1) get / set.
/// - Volatile – cleared when app is killed.
/// - Optional per-entry TTL.
class MemoryCache {
  final int maxSize;
  final Map<String, _CacheEntry> _map = {};

  MemoryCache({this.maxSize = 100});

  /// Returns the cached value or `null` if missing / expired.
  T? get<T>(String key) {
    final entry = _map[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _map.remove(key);
      return null;
    }
    // Move to end (most-recently used).
    _map.remove(key);
    _map[key] = entry;
    return entry.value as T;
  }

  /// Stores [value] under [key] with optional [ttl].
  void set<T>(String key, T value, {Duration? ttl}) {
    // Evict LRU entry if at capacity.
    if (_map.length >= maxSize && !_map.containsKey(key)) {
      _map.remove(_map.keys.first);
    }
    _map[key] = _CacheEntry(
      value: value,
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  /// Removes a single key.
  void remove(String key) => _map.remove(key);

  /// Removes all entries whose key starts with [prefix].
  void removeByPrefix(String prefix) {
    _map.removeWhere((k, _) => k.startsWith(prefix));
  }

  /// Wipes everything.
  void clear() => _map.clear();

  bool containsKey(String key) {
    final entry = _map[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _map.remove(key);
      return false;
    }
    return true;
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime? expiresAt;

  _CacheEntry({required this.value, this.expiresAt});

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
