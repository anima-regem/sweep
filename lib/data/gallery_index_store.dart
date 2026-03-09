import 'package:hive_flutter/hive_flutter.dart';

import '../models/sweep_models.dart';

class GalleryIndexStore {
  static const String _boxName = 'sweep_gallery_index';
  static const String _recordPrefix = 'media::';

  Box<dynamic>? _box;

  Future<void> ensureReady() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<List<MediaItem>> loadAllMedia() async {
    await ensureReady();

    return _box!.toMap().entries
        .where((MapEntry<dynamic, dynamic> entry) {
          return entry.key is String &&
              (entry.key as String).startsWith(_recordPrefix) &&
              entry.value is Map<dynamic, dynamic>;
        })
        .map(
          (MapEntry<dynamic, dynamic> entry) =>
              MediaItem.fromJson(entry.value as Map<dynamic, dynamic>),
        )
        .toList();
  }

  Future<void> upsertBatch(List<MediaItem> items) async {
    if (items.isEmpty) {
      return;
    }

    await ensureReady();
    await _box!.putAll(<String, dynamic>{
      for (final MediaItem item in items)
        '$_recordPrefix${item.id}': item.toJson(),
    });
  }

  Future<void> deleteIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await ensureReady();
    await _box!.deleteAll(ids.map((String id) => '$_recordPrefix$id'));
  }

  Future<bool> isEmpty() async {
    await ensureReady();
    return !_box!.keys.any(
      (dynamic key) => key is String && key.startsWith(_recordPrefix),
    );
  }

  Future<void> clear() async {
    await ensureReady();
    await _box!.deleteAll(
      _box!.keys.where(
        (dynamic key) => key is String && key.startsWith(_recordPrefix),
      ),
    );
  }
}
