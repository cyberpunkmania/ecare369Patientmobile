import '../../../../core/cache/persistent_cache.dart';
import '../../../../core/error/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationModel>> getCachedNotifications();
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  Future<void> clearCache();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final PersistentCache _cache;
  static const _boxName = 'notifications_cache';
  static const _listKey = 'notifications_list';

  NotificationLocalDataSourceImpl({required PersistentCache cache})
    : _cache = cache;

  @override
  Future<List<NotificationModel>> getCachedNotifications() async {
    final data = await _cache.get<List<dynamic>>(_listKey, boxName: _boxName);
    if (data == null) {
      throw const CacheException(message: 'No cached notifications');
    }
    return data
        .map(
          (e) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    final list = notifications.map((n) => n.toJson()).toList();
    await _cache.set(
      _listKey,
      list,
      ttl: const Duration(minutes: 2),
      boxName: _boxName,
    );
  }

  @override
  Future<void> clearCache() => _cache.clear(boxName: _boxName);
}
