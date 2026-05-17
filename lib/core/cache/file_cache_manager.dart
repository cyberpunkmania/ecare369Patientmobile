import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Thin wrapper around [DefaultCacheManager] for images and PDFs.
class FileCacheManagerWrapper {
  final DefaultCacheManager _cacheManager;

  FileCacheManagerWrapper({DefaultCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  /// Downloads (or returns from cache) the file at [url].
  Future<FileInfo> getFile(String url, {Map<String, String>? headers}) async {
    return _cacheManager.downloadFile(url, authHeaders: headers);
  }

  /// Returns a cached file if one exists, otherwise `null`.
  Future<FileInfo?> getFileFromCache(String url) {
    return _cacheManager.getFileFromCache(url);
  }

  /// Removes a specific file from the cache.
  Future<void> removeFile(String url) {
    return _cacheManager.removeFile(url);
  }

  /// Clears the entire file cache.
  Future<void> clearAll() {
    return _cacheManager.emptyCache();
  }
}
