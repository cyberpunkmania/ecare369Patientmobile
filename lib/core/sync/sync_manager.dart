import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../network/network_info.dart';

/// Queues write operations (POST / PUT / DELETE) performed while offline
/// and re-tries them once connectivity is restored.
class SyncManager {
  final NetworkInfo _networkInfo;
  final Dio _dio;
  StreamSubscription? _subscription;
  static const String _boxName = 'sync_queue';

  SyncManager({required NetworkInfo networkInfo, required Dio dio})
    : _networkInfo = networkInfo,
      _dio = dio;

  /// Start listening for connectivity changes.
  void start() {
    _subscription?.cancel();
    _subscription = _networkInfo.onConnectivityChanged.listen((_) async {
      if (await _networkInfo.isConnected) {
        await flush();
      }
    });
  }

  /// Enqueue a write operation for later execution.
  Future<void> enqueue({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final box = await _openBox();
    final entry = <String, dynamic>{
      'method': method,
      'path': path,
      'data': data != null ? json.encode(data) : null,
      'query': queryParameters != null ? json.encode(queryParameters) : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.add(entry);
  }

  /// Attempt to execute all queued operations.
  Future<void> flush() async {
    final box = await _openBox();
    if (box.isEmpty) return;

    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      final entry = Map<String, dynamic>.from(raw as Map);
      try {
        await _dio.request(
          entry['path'] as String,
          data: entry['data'] != null
              ? json.decode(entry['data'] as String)
              : null,
          queryParameters: entry['query'] != null
              ? Map<String, dynamic>.from(
                  json.decode(entry['query'] as String) as Map,
                )
              : null,
          options: Options(method: entry['method'] as String),
        );
        keysToDelete.add(key);
      } catch (_) {
        // Will retry on next connectivity event.
        break;
      }
    }

    await box.deleteAll(keysToDelete);
  }

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
