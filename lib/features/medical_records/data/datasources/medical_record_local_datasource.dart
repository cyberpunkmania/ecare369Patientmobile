import '../../../../core/cache/persistent_cache.dart';
import '../../../../core/error/exceptions.dart';
import '../models/medical_record_model.dart';

abstract class MedicalRecordLocalDataSource {
  Future<List<MedicalRecordModel>> getCachedRecords();
  Future<void> cacheRecords(List<MedicalRecordModel> records);
  Future<void> clearCache();
}

class MedicalRecordLocalDataSourceImpl implements MedicalRecordLocalDataSource {
  final PersistentCache _cache;
  static const _boxName = 'medical_records_cache';
  static const _listKey = 'records_list';

  MedicalRecordLocalDataSourceImpl({required PersistentCache cache})
    : _cache = cache;

  @override
  Future<List<MedicalRecordModel>> getCachedRecords() async {
    final data = await _cache.get<List<dynamic>>(_listKey, boxName: _boxName);
    if (data == null) {
      throw const CacheException(message: 'No cached medical records');
    }
    return data
        .map(
          (e) =>
              MedicalRecordModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<void> cacheRecords(List<MedicalRecordModel> records) async {
    final list = records.map((r) => r.toJson()).toList();
    await _cache.set(
      _listKey,
      list,
      ttl: const Duration(minutes: 30),
      boxName: _boxName,
    );
  }

  @override
  Future<void> clearCache() => _cache.clear(boxName: _boxName);
}
