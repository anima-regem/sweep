import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/sweep_models.dart';
import 'gallery_index_store.dart';
import 'gallery_scanner.dart';
import 'user_action_store.dart';

class RepositoryBootstrap {
  const RepositoryBootstrap({
    required this.discoveryMode,
    required this.scanScope,
    required this.specificFolder,
    required this.customTags,
    required this.decisions,
    required this.sessionsCompleted,
    required this.lastSessionProcessed,
    required this.lastSessionFreedBytes,
    required this.summary,
    required this.folders,
    required this.hasIndexedMedia,
  });

  final DiscoveryMode discoveryMode;
  final ScanScope scanScope;
  final String? specificFolder;
  final List<String> customTags;
  final Map<String, SwipeDecision> decisions;
  final int sessionsCompleted;
  final int lastSessionProcessed;
  final int lastSessionFreedBytes;
  final GallerySummary summary;
  final List<String> folders;
  final bool hasIndexedMedia;
}

abstract class GalleryRepository {
  Future<RepositoryBootstrap> initialize();

  GalleryPage fetchPage({
    required DiscoveryMode mode,
    required String? specificFolder,
    required int offset,
    required int limit,
    required bool includeProcessed,
    required int randomSeed,
  });

  List<MediaItem> fetchQueue({
    required DiscoveryMode mode,
    required String? specificFolder,
    required int limit,
    required int randomSeed,
  });

  GalleryPage fetchTrashPage({required int offset, required int limit});

  Map<String, List<MediaItem>> taggedCollections({required int previewLimit});

  GallerySummary get summary;
  List<String> get folders;
  List<CleanupSuggestion> suggestions();
  bool get hasIndexedMedia;

  Future<void> startScan({
    required ScanScope scope,
    required String? specificFolder,
    required void Function(ScanProgress progress) onProgress,
    required VoidCallback onDataChanged,
  });

  void prioritizeForEnrichment(
    Iterable<String> ids, {
    void Function(ScanProgress progress)? onProgress,
    VoidCallback? onDataChanged,
  });

  void setDecision(String mediaId, SwipeDecision decision);
  void clearDecision(String mediaId);
  void addCustomTag(String tag);
  void applyTags(String mediaId, List<String> tags);
  void applyMove(String mediaId, String folderName);

  Future<void> permanentlyDeleteItems(Set<String> ids);
  Future<void> moveAssets(Set<String> ids, String folderName);

  Future<void> persistPreferences({
    required DiscoveryMode discoveryMode,
    required ScanScope scanScope,
    required String? specificFolder,
    required List<String> customTags,
    required int sessionsCompleted,
    required int lastSessionProcessed,
    required int lastSessionFreedBytes,
  });
}

class LocalGalleryRepository implements GalleryRepository {
  LocalGalleryRepository({
    required GalleryScanner scanner,
    required GalleryIndexStore galleryStore,
    required UserActionStore userStore,
  }) : _scanner = scanner,
       _galleryStore = galleryStore,
       _userStore = userStore;

  final GalleryScanner _scanner;
  final GalleryIndexStore _galleryStore;
  final UserActionStore _userStore;

  final Map<String, MediaItem> _media = <String, MediaItem>{};
  final Map<String, SwipeDecision> _decisions = <String, SwipeDecision>{};
  final Map<String, MediaOverlay> _overlays = <String, MediaOverlay>{};
  List<String> _customTags = const <String>[
    'Friends',
    'Work',
    'Travel',
    'Family',
    'Documents',
  ];
  GallerySummary _summary = const GallerySummary.empty();
  List<String> _folders = const <String>[];
  int _scanToken = 0;
  int _enrichedCount = 0;
  String _scanLabel = 'Gallery ready';
  bool _scanRunning = false;
  final Set<String> _enrichmentQueue = <String>{};
  bool _enrichmentRunning = false;

  @override
  Future<RepositoryBootstrap> initialize() async {
    await _galleryStore.ensureReady();
    await _userStore.ensureReady();

    final List<MediaItem> storedMedia = await _galleryStore.loadAllMedia();
    final PersistedUserState userState = await _userStore.load();

    _media
      ..clear()
      ..addEntries(
        storedMedia.map(
          (MediaItem item) => MapEntry<String, MediaItem>(item.id, item),
        ),
      );
    _decisions
      ..clear()
      ..addAll(userState.decisions);
    _overlays
      ..clear()
      ..addAll(userState.overlays);
    _customTags = userState.customTags;
    _refreshCaches();

    return RepositoryBootstrap(
      discoveryMode: userState.discoveryMode,
      scanScope: userState.scanScope,
      specificFolder: userState.specificFolder,
      customTags: _customTags,
      decisions: Map<String, SwipeDecision>.from(_decisions),
      sessionsCompleted: userState.sessionsCompleted,
      lastSessionProcessed: userState.lastSessionProcessed,
      lastSessionFreedBytes: userState.lastSessionFreedBytes,
      summary: _summary,
      folders: _folders,
      hasIndexedMedia: _media.isNotEmpty,
    );
  }

  @override
  GalleryPage fetchPage({
    required DiscoveryMode mode,
    required String? specificFolder,
    required int offset,
    required int limit,
    required bool includeProcessed,
    required int randomSeed,
  }) {
    final List<MediaItem> matches = _sortedItemsForMode(
      mode: mode,
      specificFolder: specificFolder,
      includeProcessed: includeProcessed,
      randomSeed: randomSeed,
    );
    final int safeOffset = offset.clamp(0, matches.length);
    final int end = safeOffset + limit > matches.length
        ? matches.length
        : safeOffset + limit;

    return GalleryPage(
      items: matches.sublist(safeOffset, end),
      offset: safeOffset,
      hasMore: end < matches.length,
      totalCount: matches.length,
    );
  }

  @override
  List<MediaItem> fetchQueue({
    required DiscoveryMode mode,
    required String? specificFolder,
    required int limit,
    required int randomSeed,
  }) {
    return fetchPage(
      mode: mode,
      specificFolder: specificFolder,
      offset: 0,
      limit: limit,
      includeProcessed: false,
      randomSeed: randomSeed,
    ).items;
  }

  @override
  GalleryPage fetchTrashPage({required int offset, required int limit}) {
    final List<MediaItem> items = _resolvedItems()
        .where((MediaItem item) => _decisions[item.id] == SwipeDecision.delete)
        .toList()
      ..sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt));

    final int safeOffset = offset.clamp(0, items.length);
    final int end = safeOffset + limit > items.length
        ? items.length
        : safeOffset + limit;

    return GalleryPage(
      items: items.sublist(safeOffset, end),
      offset: safeOffset,
      hasMore: end < items.length,
      totalCount: items.length,
    );
  }

  @override
  Map<String, List<MediaItem>> taggedCollections({required int previewLimit}) {
    final Map<String, List<MediaItem>> collections = <String, List<MediaItem>>{};

    for (final MediaItem item in _resolvedItems()) {
      for (final String tag in item.tags) {
        collections.putIfAbsent(tag, () => <MediaItem>[]).add(item);
      }
    }

    final List<String> keys = collections.keys.toList()..sort();
    return <String, List<MediaItem>>{
      for (final String key in keys)
        key: (collections[key]!..sort(
              (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
            ))
            .take(previewLimit)
            .toList(),
    };
  }

  @override
  GallerySummary get summary => _summary;

  @override
  List<String> get folders => _folders;

  @override
  bool get hasIndexedMedia => _media.isNotEmpty;

  @override
  List<CleanupSuggestion> suggestions() {
    final List<MediaItem> screenshots = _sortedItemsForMode(
      mode: DiscoveryMode.screenshots,
      specificFolder: null,
      includeProcessed: true,
      randomSeed: 0,
    );
    final List<MediaItem> largeFiles = _sortedItemsForMode(
      mode: DiscoveryMode.largestFiles,
      specificFolder: null,
      includeProcessed: true,
      randomSeed: 0,
    ).take(50).toList();
    final List<MediaItem> oldMedia = _sortedItemsForMode(
      mode: DiscoveryMode.oldestMedia,
      specificFolder: null,
      includeProcessed: true,
      randomSeed: 0,
    ).where((MediaItem item) => item.createdAt.year <= 2019).toList();

    return <CleanupSuggestion>[
      CleanupSuggestion(
        title: 'Clean screenshots',
        subtitle: 'Quick win for clutter and storage',
        mode: DiscoveryMode.screenshots,
        itemCount: screenshots.length,
        estimatedBytes: screenshots.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.safeSizeBytes,
        ),
      ),
      CleanupSuggestion(
        title: 'Large videos',
        subtitle: 'Highest storage impact first',
        mode: DiscoveryMode.largestFiles,
        itemCount: largeFiles.length,
        estimatedBytes: largeFiles.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.safeSizeBytes,
        ),
      ),
      CleanupSuggestion(
        title: 'Old photos (<=2019)',
        subtitle: 'Rediscover forgotten media',
        mode: DiscoveryMode.oldestMedia,
        itemCount: oldMedia.length,
        estimatedBytes: oldMedia.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.safeSizeBytes,
        ),
      ),
    ];
  }

  @override
  Future<void> startScan({
    required ScanScope scope,
    required String? specificFolder,
    required void Function(ScanProgress progress) onProgress,
    required VoidCallback onDataChanged,
  }) async {
    final int token = ++_scanToken;
    _scanRunning = true;

    onProgress(
      ScanProgress(
        isRunning: true,
        indexedCount: _media.length,
        enrichedCount: _enrichedCount,
        label: 'Preparing scan...',
      ),
    );

    await for (final GalleryScanBatch batch in _scanner.scanBatches(
      scope: scope,
      specificFolder: specificFolder,
    )) {
      if (token != _scanToken) {
        return;
      }

      if (batch.items.isNotEmpty) {
        for (final MediaItem item in batch.items) {
          final MediaItem? existing = _media[item.id];
          if (existing == null) {
            _media[item.id] = item;
            continue;
          }

          _media[item.id] = item.copyWith(
            sizeBytes: existing.sizeBytes ?? item.sizeBytes,
            duplicateStatus: existing.duplicateStatus == DuplicateStatus.unresolved
                ? item.duplicateStatus
                : existing.duplicateStatus,
            tags: existing.tags,
            movedToFolder: existing.movedToFolder,
          );
        }

        await _galleryStore.upsertBatch(batch.items);
        _refreshCaches();
        onDataChanged();
        prioritizeForEnrichment(
          batch.items.map((MediaItem item) => item.id),
          onProgress: onProgress,
          onDataChanged: onDataChanged,
        );
      }

      _scanLabel = batch.complete ? 'Index ready' : batch.label;
      if (batch.complete) {
        _scanRunning = false;
      }
      onProgress(
        ScanProgress(
          isRunning: _scanRunning,
          indexedCount: _media.length,
          enrichedCount: _enrichedCount,
          label: _scanLabel,
          totalAlbums: batch.albumCount,
        ),
      );
    }
  }

  @override
  void prioritizeForEnrichment(
    Iterable<String> ids, {
    void Function(ScanProgress progress)? onProgress,
    VoidCallback? onDataChanged,
  }) {
    for (final String id in ids) {
      final MediaItem? item = _media[id];
      if (item == null) {
        continue;
      }
      if (item.assetId == null) {
        continue;
      }
      if (item.sizeBytes != null &&
          item.duplicateStatus != DuplicateStatus.unresolved) {
        continue;
      }
      _enrichmentQueue.add(id);
    }

    if (_enrichmentRunning || _enrichmentQueue.isEmpty) {
      return;
    }

    _enrichmentRunning = true;
    unawaited(_runEnrichment(onProgress: onProgress, onDataChanged: onDataChanged));
  }

  @override
  void setDecision(String mediaId, SwipeDecision decision) {
    _decisions[mediaId] = decision;
    _refreshCaches();
    unawaited(_userStore.saveDecision(mediaId, decision));
  }

  @override
  void clearDecision(String mediaId) {
    if (_decisions.remove(mediaId) == null) {
      return;
    }
    _refreshCaches();
    unawaited(_userStore.deleteDecision(mediaId));
  }

  @override
  void addCustomTag(String tag) {
    final String normalized = tag.trim();
    if (normalized.isEmpty || _customTags.contains(normalized)) {
      return;
    }

    _customTags = <String>[..._customTags, normalized];
  }

  @override
  void applyTags(String mediaId, List<String> tags) {
    final MediaItem? current = _resolvedMediaById(mediaId);
    if (current == null) {
      return;
    }

    final Set<String> merged = <String>{
      ...current.tags,
      ...tags.map((String value) => value.trim()).where((String value) {
        return value.isNotEmpty;
      }),
    };
    final MediaOverlay base = _overlays[mediaId] ?? const MediaOverlay();
    final MediaOverlay next = base.copyWith(tags: merged.toList());
    _saveOverlay(mediaId, next);
  }

  @override
  void applyMove(String mediaId, String folderName) {
    final String normalized = folderName.trim();
    if (normalized.isEmpty) {
      return;
    }

    final MediaOverlay base = _overlays[mediaId] ?? const MediaOverlay();
    final MediaOverlay next = base.copyWith(movedToFolder: normalized);
    _saveOverlay(mediaId, next);
  }

  @override
  Future<void> permanentlyDeleteItems(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final Set<String> idSet = Set<String>.from(ids);
    final List<String> assetIds = idSet
        .map((String id) => _media[id]?.assetId)
        .whereType<String>()
        .toList();

    if (assetIds.isNotEmpty) {
      try {
        await PhotoManager.editor.deleteWithIds(assetIds);
      } catch (_) {
        // Local cleanup still proceeds.
      }
    }

    for (final String id in idSet) {
      _media.remove(id);
      _decisions.remove(id);
      _overlays.remove(id);
      _enrichmentQueue.remove(id);
    }

    await _galleryStore.deleteIds(idSet);
    await _userStore.deleteMediaState(idSet);
    _refreshCaches();
  }

  @override
  Future<void> moveAssets(Set<String> ids, String folderName) async {
    if (ids.isEmpty) {
      return;
    }

    final List<String> assetIds = ids
        .map((String id) => _media[id]?.assetId)
        .whereType<String>()
        .toList();

    if (assetIds.isEmpty) {
      return;
    }

    final List<AssetEntity> entities = <AssetEntity>[];
    for (final String assetId in assetIds) {
      final AssetEntity? entity = await AssetEntity.fromId(assetId);
      if (entity != null) {
        entities.add(entity);
      }
    }

    if (entities.isEmpty) {
      return;
    }

    try {
      await PhotoManager.editor.android.moveAssetsToPath(
        entities: entities,
        targetPath: 'Pictures/$folderName',
      );
    } catch (_) {
      // Local organization state remains available if native move is unsupported.
    }
  }

  @override
  Future<void> persistPreferences({
    required DiscoveryMode discoveryMode,
    required ScanScope scanScope,
    required String? specificFolder,
    required List<String> customTags,
    required int sessionsCompleted,
    required int lastSessionProcessed,
    required int lastSessionFreedBytes,
  }) {
    _customTags = customTags;
    return _userStore.savePreferences(
      discoveryMode: discoveryMode,
      scanScope: scanScope,
      specificFolder: specificFolder,
      customTags: customTags,
      sessionsCompleted: sessionsCompleted,
      lastSessionProcessed: lastSessionProcessed,
      lastSessionFreedBytes: lastSessionFreedBytes,
    );
  }

  Future<void> _runEnrichment({
    void Function(ScanProgress progress)? onProgress,
    VoidCallback? onDataChanged,
  }) async {
    while (_enrichmentQueue.isNotEmpty) {
      final String id = _enrichmentQueue.first;
      _enrichmentQueue.remove(id);

      final MediaItem? updated = await _enrichMedia(id);
      if (updated != null) {
        _media[id] = updated;
        await _galleryStore.upsertBatch(<MediaItem>[updated]);
      }

      if (updated != null) {
        _refreshCaches();
        onDataChanged?.call();
      }

      onProgress?.call(
        ScanProgress(
          isRunning: _scanRunning,
          indexedCount: _media.length,
          enrichedCount: _enrichedCount,
          label: _scanRunning ? _scanLabel : 'Refining metadata',
        ),
      );
    }

    _enrichmentRunning = false;
    _refreshCaches();
    onDataChanged?.call();
  }

  Future<MediaItem?> _enrichMedia(String id) async {
    final MediaItem? current = _media[id];
    if (current == null || current.assetId == null) {
      return null;
    }

    final AssetEntity? asset = await AssetEntity.fromId(current.assetId!);
    if (asset == null) {
      return null;
    }

    int? sizeBytes = current.sizeBytes;
    sizeBytes ??= await _sizeForAsset(asset);

    DuplicateStatus duplicateStatus = current.duplicateStatus;
    if (sizeBytes != null &&
        duplicateStatus == DuplicateStatus.unresolved) {
      duplicateStatus = _resolveDuplicateStatus(
        current.copyWith(sizeBytes: sizeBytes),
      );
    }

    _enrichedCount += 1;

    if (sizeBytes == current.sizeBytes &&
        duplicateStatus == current.duplicateStatus) {
      return null;
    }

    return current.copyWith(
      sizeBytes: sizeBytes,
      duplicateStatus: duplicateStatus,
    );
  }

  DuplicateStatus _resolveDuplicateStatus(MediaItem candidate) {
    if (candidate.sizeBytes == null) {
      return DuplicateStatus.unresolved;
    }

    final bool hasPrimary = _media.values.any((MediaItem other) {
      if (other.id == candidate.id || other.sizeBytes == null) {
        return false;
      }
      return other.sizeBytes == candidate.sizeBytes &&
          other.width == candidate.width &&
          other.height == candidate.height &&
          other.kind == candidate.kind;
    });

    return hasPrimary ? DuplicateStatus.duplicate : DuplicateStatus.unique;
  }

  Future<int?> _sizeForAsset(AssetEntity asset) async {
    try {
      final File? file = await asset.file;
      if (file == null) {
        return null;
      }
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  void _saveOverlay(String mediaId, MediaOverlay overlay) {
    if (overlay.isEmpty) {
      _overlays.remove(mediaId);
      unawaited(_userStore.deleteOverlay(mediaId));
    } else {
      _overlays[mediaId] = overlay;
      unawaited(_userStore.saveOverlay(mediaId, overlay));
    }
    _refreshCaches();
  }

  void _refreshCaches() {
    _folders = _resolvedItems()
        .map((MediaItem item) => item.resolvedFolder)
        .toSet()
        .toList()
      ..sort();
    _summary = _computeSummary();
  }

  GallerySummary _computeSummary() {
    final List<MediaItem> items = _resolvedItems();
    final int totalSize = items.fold<int>(
      0,
      (int sum, MediaItem item) => sum + item.safeSizeBytes,
    );
    final int duplicateCount = items
        .where((MediaItem item) => item.isDuplicate)
        .length;
    final int unresolvedSizeCount = items
        .where((MediaItem item) {
          return item.sizeBytes == null ||
              item.duplicateStatus == DuplicateStatus.unresolved;
        })
        .length;

    final List<MediaItem> largestVideos = items
        .where((MediaItem item) => item.kind == MediaKind.video)
        .toList()
      ..sort((MediaItem a, MediaItem b) {
        return b.safeSizeBytes.compareTo(a.safeSizeBytes);
      });

    final Map<String, FolderUsage> folderMap = <String, FolderUsage>{};
    for (final MediaItem item in items) {
      final FolderUsage? existing = folderMap[item.resolvedFolder];
      folderMap[item.resolvedFolder] = FolderUsage(
        folder: item.resolvedFolder,
        itemCount: (existing?.itemCount ?? 0) + 1,
        totalSizeBytes: (existing?.totalSizeBytes ?? 0) + item.safeSizeBytes,
        unresolvedSizeCount:
            (existing?.unresolvedSizeCount ?? 0) + (item.sizeBytes == null ? 1 : 0),
      );
    }

    final List<FolderUsage> folderUsage = folderMap.values.toList()
      ..sort((FolderUsage a, FolderUsage b) {
        return b.totalSizeBytes.compareTo(a.totalSizeBytes);
      });

    final int potentialFreedBytes = items
        .where((MediaItem item) => _decisions[item.id] == SwipeDecision.delete)
        .fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.safeSizeBytes,
        );

    return GallerySummary(
      totalMediaCount: items.length,
      totalSizeBytes: totalSize,
      duplicateCount: duplicateCount,
      potentialFreedBytes: potentialFreedBytes,
      largestVideos: largestVideos.take(5).toList(),
      folderUsage: folderUsage,
      unresolvedSizeCount: unresolvedSizeCount,
      isPartial: unresolvedSizeCount > 0,
    );
  }

  List<MediaItem> _resolvedItems() {
    return _media.values.map(_applyOverlay).toList();
  }

  MediaItem? _resolvedMediaById(String id) {
    final MediaItem? item = _media[id];
    if (item == null) {
      return null;
    }
    return _applyOverlay(item);
  }

  MediaItem _applyOverlay(MediaItem base) {
    final MediaOverlay? overlay = _overlays[base.id];
    if (overlay == null) {
      return base;
    }

    final Set<String> mergedTags = <String>{...base.tags, ...overlay.tags};
    return base.copyWith(
      tags: mergedTags.toList(),
      movedToFolder: overlay.movedToFolder ?? base.movedToFolder,
    );
  }

  List<MediaItem> _sortedItemsForMode({
    required DiscoveryMode mode,
    required String? specificFolder,
    required bool includeProcessed,
    required int randomSeed,
  }) {
    final List<MediaItem> filtered = _resolvedItems().where((MediaItem item) {
      if (!includeProcessed && _decisions.containsKey(item.id)) {
        return false;
      }
      return _matchesMode(item, mode: mode, specificFolder: specificFolder);
    }).toList();

    switch (mode) {
      case DiscoveryMode.largestFiles:
        filtered.sort((MediaItem a, MediaItem b) {
          return b.safeSizeBytes.compareTo(a.safeSizeBytes);
        });
        break;
      case DiscoveryMode.oldestMedia:
        filtered.sort((MediaItem a, MediaItem b) {
          return a.createdAt.compareTo(b.createdAt);
        });
        break;
      case DiscoveryMode.random:
        filtered.sort((MediaItem a, MediaItem b) {
          return _randomOrder(a.id, randomSeed).compareTo(
            _randomOrder(b.id, randomSeed),
          );
        });
        break;
      default:
        filtered.sort((MediaItem a, MediaItem b) {
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    return filtered;
  }

  bool _matchesMode(
    MediaItem item, {
    required DiscoveryMode mode,
    required String? specificFolder,
  }) {
    final String folder = item.resolvedFolder.toLowerCase();

    switch (mode) {
      case DiscoveryMode.all:
      case DiscoveryMode.largestFiles:
      case DiscoveryMode.oldestMedia:
      case DiscoveryMode.random:
        return true;
      case DiscoveryMode.duplicates:
        return item.isDuplicate;
      case DiscoveryMode.screenshots:
        return folder.contains('screenshot');
      case DiscoveryMode.whatsapp:
        return folder.contains('whatsapp');
      case DiscoveryMode.cameraRoll:
        return folder.contains('camera') || folder.contains('dcim');
      case DiscoveryMode.downloads:
        return folder.contains('download');
      case DiscoveryMode.specificFolder:
        if (specificFolder == null || specificFolder.trim().isEmpty) {
          return true;
        }
        return folder == specificFolder.toLowerCase();
    }
  }

  int _randomOrder(String id, int randomSeed) {
    return Object.hash(id, randomSeed);
  }
}
