/// Determines how [CacheManager] resolves data.
enum CachePolicy {
  /// Fetch from network first → save to L1 + L2 → return.
  networkFirst,

  /// Check L1 → L2 → if miss, fetch from network → save to L1 + L2.
  cacheFirst,

  /// L1 → L2 → throw [CacheException] if miss. Never hits network.
  cacheOnly,

  /// Fetch from network only – no cache read/write.
  networkOnly,
}
