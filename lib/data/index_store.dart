import 'package:hive_flutter/hive_flutter.dart';

class IndexStore {
  static const String _boxName = 'sweep_state';
  static const String _stateKey = 'state';

  Box<dynamic>? _box;

  Future<void> ensureReady() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<Map<String, dynamic>?> loadState() async {
    await ensureReady();
    final dynamic data = _box!.get(_stateKey);
    if (data is Map<dynamic, dynamic>) {
      return data.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Future<void> saveState(Map<String, dynamic> json) async {
    await ensureReady();
    await _box!.put(_stateKey, json);
  }

  Future<void> clear() async {
    await ensureReady();
    await _box!.delete(_stateKey);
  }
}
