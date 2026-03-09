import 'package:hive_flutter/hive_flutter.dart';

import '../models/sweep_models.dart';

class PersistedUserState {
  const PersistedUserState({
    required this.discoveryMode,
    required this.scanScope,
    required this.specificFolder,
    required this.customTags,
    required this.decisions,
    required this.overlays,
    required this.sessionsCompleted,
    required this.lastSessionProcessed,
    required this.lastSessionFreedBytes,
  });

  final DiscoveryMode discoveryMode;
  final ScanScope scanScope;
  final String? specificFolder;
  final List<String> customTags;
  final Map<String, SwipeDecision> decisions;
  final Map<String, MediaOverlay> overlays;
  final int sessionsCompleted;
  final int lastSessionProcessed;
  final int lastSessionFreedBytes;
}

class UserActionStore {
  static const String _boxName = 'sweep_user_state';
  static const String _prefsKey = 'prefs';
  static const String _decisionPrefix = 'decision::';
  static const String _overlayPrefix = 'overlay::';
  static const List<String> _defaultTags = <String>[
    'Friends',
    'Work',
    'Travel',
    'Family',
    'Documents',
  ];

  Box<dynamic>? _box;

  Future<void> ensureReady() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<PersistedUserState> load() async {
    await ensureReady();

    final Map<dynamic, dynamic> prefs =
        _box!.get(_prefsKey) as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{};

    final Map<String, SwipeDecision> decisions = <String, SwipeDecision>{};
    final Map<String, MediaOverlay> overlays = <String, MediaOverlay>{};

    for (final dynamic key in _box!.keys) {
      if (key is! String) {
        continue;
      }
      if (key.startsWith(_decisionPrefix)) {
        final dynamic value = _box!.get(key);
        if (value is String) {
          decisions[key.substring(_decisionPrefix.length)] =
              SwipeDecision.values.byName(value);
        }
      } else if (key.startsWith(_overlayPrefix)) {
        final dynamic value = _box!.get(key);
        if (value is Map<dynamic, dynamic>) {
          overlays[key.substring(_overlayPrefix.length)] = MediaOverlay.fromJson(
            value,
          );
        }
      }
    }

    return PersistedUserState(
      discoveryMode: DiscoveryMode.values.byName(
        prefs['discoveryMode'] as String? ?? DiscoveryMode.all.name,
      ),
      scanScope: ScanScope.values.byName(
        prefs['scanScope'] as String? ?? ScanScope.entireGallery.name,
      ),
      specificFolder: prefs['specificFolder'] as String?,
      customTags: (prefs['customTags'] as List<dynamic>? ?? _defaultTags)
          .map((dynamic value) => value as String)
          .toList(),
      decisions: decisions,
      overlays: overlays,
      sessionsCompleted: prefs['sessionsCompleted'] as int? ?? 0,
      lastSessionProcessed: prefs['lastSessionProcessed'] as int? ?? 0,
      lastSessionFreedBytes: prefs['lastSessionFreedBytes'] as int? ?? 0,
    );
  }

  Future<void> savePreferences({
    required DiscoveryMode discoveryMode,
    required ScanScope scanScope,
    required String? specificFolder,
    required List<String> customTags,
    required int sessionsCompleted,
    required int lastSessionProcessed,
    required int lastSessionFreedBytes,
  }) async {
    await ensureReady();
    await _box!.put(_prefsKey, <String, dynamic>{
      'discoveryMode': discoveryMode.name,
      'scanScope': scanScope.name,
      'specificFolder': specificFolder,
      'customTags': customTags,
      'sessionsCompleted': sessionsCompleted,
      'lastSessionProcessed': lastSessionProcessed,
      'lastSessionFreedBytes': lastSessionFreedBytes,
    });
  }

  Future<void> saveDecision(String mediaId, SwipeDecision decision) async {
    await ensureReady();
    await _box!.put('$_decisionPrefix$mediaId', decision.name);
  }

  Future<void> deleteDecision(String mediaId) async {
    await ensureReady();
    await _box!.delete('$_decisionPrefix$mediaId');
  }

  Future<void> saveOverlay(String mediaId, MediaOverlay overlay) async {
    await ensureReady();
    await _box!.put('$_overlayPrefix$mediaId', overlay.toJson());
  }

  Future<void> deleteOverlay(String mediaId) async {
    await ensureReady();
    await _box!.delete('$_overlayPrefix$mediaId');
  }

  Future<void> deleteMediaState(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await ensureReady();
    await _box!.deleteAll(<String>[
      for (final String id in ids) '$_decisionPrefix$id',
      for (final String id in ids) '$_overlayPrefix$id',
    ]);
  }
}
