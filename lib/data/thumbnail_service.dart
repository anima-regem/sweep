import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

final Provider<ThumbnailService> thumbnailServiceProvider =
    Provider<ThumbnailService>((Ref ref) {
      final ThumbnailService service = ThumbnailService();
      ref.onDispose(service.dispose);
      return service;
    });

class ThumbnailService with WidgetsBindingObserver {
  static const int _minThumbnailSize = 120;
  static const int _maxThumbnailSize = 768;

  ThumbnailService({this.capacity = 160}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final int capacity;
  final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List?>> _pending =
      <String, Future<Uint8List?>>{};

  Future<Uint8List?> load(String assetId, {required int size}) {
    final int normalizedSize = _normalizeSize(size);
    final String key = '$assetId::$normalizedSize';
    final Uint8List? cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return Future<Uint8List?>.value(cached);
    }

    final Future<Uint8List?>? inFlight = _pending[key];
    if (inFlight != null) {
      return inFlight;
    }

    final Future<Uint8List?> request = _fetch(assetId, normalizedSize, key);
    _pending[key] = request;
    return request;
  }

  int _normalizeSize(int size) {
    final int clamped = size.clamp(_minThumbnailSize, _maxThumbnailSize);
    return ((clamped + 31) ~/ 32) * 32;
  }

  Future<Uint8List?> _fetch(String assetId, int size, String key) async {
    try {
      final AssetEntity? asset = await AssetEntity.fromId(assetId);
      if (asset == null) {
        return null;
      }

      final Uint8List? data = await asset.thumbnailDataWithSize(
        ThumbnailSize.square(size),
      );
      if (data != null) {
        _cache.remove(key);
        _cache[key] = data;
        while (_cache.length > capacity) {
          _cache.remove(_cache.keys.first);
        }
      }
      return data;
    } finally {
      _pending.remove(key);
    }
  }

  @override
  void didHaveMemoryPressure() {
    _cache.clear();
    _pending.clear();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cache.clear();
    _pending.clear();
  }
}
