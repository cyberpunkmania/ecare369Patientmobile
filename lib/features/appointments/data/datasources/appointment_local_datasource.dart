import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../core/cache/persistent_cache.dart';
import '../models/my_appointment_dto.dart';

abstract class AppointmentLocalDataSource {
  Future<List<MyAppointmentDto>> getCachedAppointments();
  Future<void> cacheAppointments(List<MyAppointmentDto> appointments);
  Future<void> clearCache();
}

class AppointmentLocalDataSourceImpl implements AppointmentLocalDataSource {
  final PersistentCache _cache;
  static const _boxName = 'appointments_cache';
  static const _listKey = 'appointments_list';

  AppointmentLocalDataSourceImpl({required PersistentCache cache})
    : _cache = cache;

  @override
  Future<List<MyAppointmentDto>> getCachedAppointments() async {
    final data = await _cache.get<List<dynamic>>(_listKey, boxName: _boxName);
    if (data == null) {
      throw const CacheException(message: 'No cached appointments');
    }
    return data
        .map(
          (e) => MyAppointmentDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  @override
  Future<void> cacheAppointments(List<MyAppointmentDto> appointments) async {
    final list = appointments.map((a) => a.toJson()).toList();
    await _cache.set(
      _listKey,
      list,
      ttl: const Duration(minutes: 5),
      boxName: _boxName,
    );
  }

  @override
  Future<void> clearCache() => _cache.clear(boxName: _boxName);
}
