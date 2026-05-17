import 'dart:convert';

import 'package:hive/hive.dart';

/// Hive-backed persistent cache.
///
/// Survives app restarts. TTL is stored as a DateTime ISO-8601 string
/// alongside the JSON-encoded value.
class PersistentCache {
  static const String _defaultBoxName = 'persistent_cache';

  Future<Box> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName);
  }

  /// Returns the cached value or `null` if missing / expired.
  Future<T?> get<T>(String key, {String boxName = _defaultBoxName}) async {
    final box = await _openBox(boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw as Map);
    final expiresAtStr = map['expires_at'] as String?;

    if (expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isAfter(expiresAt)) {
        await box.delete(key);
        return null;
      }
    }

    final value = json.decode(map['value'] as String);
    // json.decode returns List<dynamic>/Map<String,dynamic>, never a typed
    // generic list. Attempting a direct cast of List<dynamic> to
    // List<SomeDto> throws a runtime TypeError, so we catch it and treat a
    // type mismatch as a cache miss — the fetcher will rebuild the entry.
    try {
      return value as T;
    } catch (_) {
      await box.delete(key);
      return null;
    }
  }

  /// Stores [value] under [key] with optional [ttl].
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    String boxName = _defaultBoxName,
  }) async {
    final box = await _openBox(boxName);
    final entry = <String, dynamic>{
      'value': json.encode(value),
      if (ttl != null) 'expires_at': DateTime.now().add(ttl).toIso8601String(),
    };
    await box.put(key, entry);
  }

  /// Removes a single key.
  Future<void> remove(String key, {String boxName = _defaultBoxName}) async {
    final box = await _openBox(boxName);
    await box.delete(key);
  }

  /// Removes all entries whose key starts with [prefix].
  Future<void> removeByPrefix(
    String prefix, {
    String boxName = _defaultBoxName,
  }) async {
    final box = await _openBox(boxName);
    final keysToRemove = box.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    await box.deleteAll(keysToRemove);
  }

  /// Clears the whole box.
  Future<void> clear({String boxName = _defaultBoxName}) async {
    final box = await _openBox(boxName);
    await box.clear();
  }
}
