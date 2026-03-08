import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/gallery_scanner.dart';
import '../data/index_store.dart';
import '../models/sweep_models.dart';

final Provider<GalleryScanner> galleryScannerProvider =
    Provider<GalleryScanner>((Ref ref) {
      return const GalleryScanner();
    });

final Provider<IndexStore> indexStoreProvider = Provider<IndexStore>((Ref ref) {
  return IndexStore();
});

final StateNotifierProvider<SweepController, SweepState>
sweepControllerProvider = StateNotifierProvider<SweepController, SweepState>((
  Ref ref,
) {
  final SweepController controller = SweepController(
    scanner: ref.read(galleryScannerProvider),
    store: ref.read(indexStoreProvider),
  );
  controller.initialize();
  return controller;
});

class SweepState {
  const SweepState({
    required this.isLoading,
    required this.initialized,
    required this.media,
    required this.discoveryMode,
    required this.scanScope,
    required this.specificFolder,
    required this.decisions,
    required this.selectedBulkIds,
    required this.customTags,
    required this.sessionsCompleted,
    required this.currentSessionProcessed,
    required this.currentSessionFreedBytes,
    required this.lastSessionProcessed,
    required this.lastSessionFreedBytes,
    required this.showCompletion,
    required this.statusMessage,
  });

  factory SweepState.initial() {
    return const SweepState(
      isLoading: false,
      initialized: false,
      media: <MediaItem>[],
      discoveryMode: DiscoveryMode.all,
      scanScope: ScanScope.entireGallery,
      specificFolder: null,
      decisions: <String, SwipeDecision>{},
      selectedBulkIds: <String>{},
      customTags: <String>['Friends', 'Work', 'Travel', 'Family', 'Documents'],
      sessionsCompleted: 0,
      currentSessionProcessed: 0,
      currentSessionFreedBytes: 0,
      lastSessionProcessed: 0,
      lastSessionFreedBytes: 0,
      showCompletion: false,
      statusMessage: null,
    );
  }

  final bool isLoading;
  final bool initialized;
  final List<MediaItem> media;
  final DiscoveryMode discoveryMode;
  final ScanScope scanScope;
  final String? specificFolder;
  final Map<String, SwipeDecision> decisions;
  final Set<String> selectedBulkIds;
  final List<String> customTags;
  final int sessionsCompleted;
  final int currentSessionProcessed;
  final int currentSessionFreedBytes;
  final int lastSessionProcessed;
  final int lastSessionFreedBytes;
  final bool showCompletion;
  final String? statusMessage;

  SweepState copyWith({
    bool? isLoading,
    bool? initialized,
    List<MediaItem>? media,
    DiscoveryMode? discoveryMode,
    ScanScope? scanScope,
    String? specificFolder,
    bool clearSpecificFolder = false,
    Map<String, SwipeDecision>? decisions,
    Set<String>? selectedBulkIds,
    List<String>? customTags,
    int? sessionsCompleted,
    int? currentSessionProcessed,
    int? currentSessionFreedBytes,
    int? lastSessionProcessed,
    int? lastSessionFreedBytes,
    bool? showCompletion,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return SweepState(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      media: media ?? this.media,
      discoveryMode: discoveryMode ?? this.discoveryMode,
      scanScope: scanScope ?? this.scanScope,
      specificFolder: clearSpecificFolder
          ? null
          : (specificFolder ?? this.specificFolder),
      decisions: decisions ?? this.decisions,
      selectedBulkIds: selectedBulkIds ?? this.selectedBulkIds,
      customTags: customTags ?? this.customTags,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      currentSessionProcessed:
          currentSessionProcessed ?? this.currentSessionProcessed,
      currentSessionFreedBytes:
          currentSessionFreedBytes ?? this.currentSessionFreedBytes,
      lastSessionProcessed: lastSessionProcessed ?? this.lastSessionProcessed,
      lastSessionFreedBytes:
          lastSessionFreedBytes ?? this.lastSessionFreedBytes,
      showCompletion: showCompletion ?? this.showCompletion,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'media': media.map((MediaItem item) => item.toJson()).toList(),
      'discoveryMode': discoveryMode.name,
      'scanScope': scanScope.name,
      'specificFolder': specificFolder,
      'decisions': decisions.map(
        (String key, SwipeDecision value) =>
            MapEntry<String, String>(key, value.name),
      ),
      'selectedBulkIds': selectedBulkIds.toList(),
      'customTags': customTags,
      'sessionsCompleted': sessionsCompleted,
      'lastSessionProcessed': lastSessionProcessed,
      'lastSessionFreedBytes': lastSessionFreedBytes,
    };
  }

  factory SweepState.fromJson(Map<String, dynamic> json) {
    final Map<String, SwipeDecision> decodedDecisions =
        ((json['decisions'] as Map<dynamic, dynamic>? ??
                const <dynamic, dynamic>{}))
            .map(
              (dynamic key, dynamic value) => MapEntry<String, SwipeDecision>(
                key as String,
                SwipeDecision.values.byName(value as String),
              ),
            );

    return SweepState(
      isLoading: false,
      initialized: true,
      media: (json['media'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (dynamic value) =>
                MediaItem.fromJson(value as Map<dynamic, dynamic>),
          )
          .toList(),
      discoveryMode: DiscoveryMode.values.byName(
        json['discoveryMode'] as String? ?? DiscoveryMode.all.name,
      ),
      scanScope: ScanScope.values.byName(
        json['scanScope'] as String? ?? ScanScope.entireGallery.name,
      ),
      specificFolder: json['specificFolder'] as String?,
      decisions: decodedDecisions,
      selectedBulkIds:
          (json['selectedBulkIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => value as String)
              .toSet(),
      customTags: (json['customTags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value as String)
          .toList(),
      sessionsCompleted: json['sessionsCompleted'] as int? ?? 0,
      currentSessionProcessed: 0,
      currentSessionFreedBytes: 0,
      lastSessionProcessed: json['lastSessionProcessed'] as int? ?? 0,
      lastSessionFreedBytes: json['lastSessionFreedBytes'] as int? ?? 0,
      showCompletion: false,
      statusMessage: null,
    );
  }
}

class SweepController extends StateNotifier<SweepState> {
  SweepController({required GalleryScanner scanner, required IndexStore store})
    : _scanner = scanner,
      _store = store,
      _random = Random(),
      super(SweepState.initial());

  final GalleryScanner _scanner;
  final IndexStore _store;
  final Random _random;

  Future<void> initialize() async {
    if (state.initialized) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      statusMessage: 'Loading local index...',
    );

    await _store.ensureReady();
    final Map<String, dynamic>? persisted = await _store.loadState();

    if (persisted != null) {
      state = SweepState.fromJson(
        persisted,
      ).copyWith(isLoading: false, initialized: true, clearStatusMessage: true);
      return;
    }

    await scanGallery(scope: ScanScope.entireGallery);
  }

  Future<void> scanGallery({ScanScope? scope, String? specificFolder}) async {
    final ScanScope selectedScope = scope ?? state.scanScope;

    state = state.copyWith(
      isLoading: true,
      statusMessage:
          'Scanning gallery...'
          ' (${selectedScope.label})',
      scanScope: selectedScope,
      specificFolder: specificFolder,
      clearSpecificFolder: selectedScope != ScanScope.specificFolder,
      selectedBulkIds: <String>{},
      currentSessionProcessed: 0,
      currentSessionFreedBytes: 0,
      showCompletion: false,
    );

    final List<MediaItem> scanned = await _scanner.scan(
      scope: selectedScope,
      specificFolder: specificFolder,
    );

    final DiscoveryMode defaultMode = _modeForScope(selectedScope);

    state = state.copyWith(
      isLoading: false,
      initialized: true,
      media: scanned,
      decisions: <String, SwipeDecision>{},
      selectedBulkIds: <String>{},
      discoveryMode: defaultMode,
      clearSpecificFolder: selectedScope != ScanScope.specificFolder,
      specificFolder: selectedScope == ScanScope.specificFolder
          ? specificFolder
          : state.specificFolder,
      statusMessage: 'Scan complete: ${scanned.length} items indexed',
    );

    _persist();
  }

  void setDiscoveryMode(DiscoveryMode mode, {String? folderName}) {
    state = state.copyWith(
      discoveryMode: mode,
      specificFolder: mode == DiscoveryMode.specificFolder
          ? folderName ?? state.specificFolder
          : state.specificFolder,
      clearSpecificFolder: mode != DiscoveryMode.specificFolder,
      selectedBulkIds: <String>{},
      showCompletion: false,
      clearStatusMessage: true,
    );

    _persist();
  }

  List<MediaItem> mediaForActiveMode({bool includeProcessed = true}) {
    final Iterable<MediaItem> byMode = _mediaByMode(state.discoveryMode);

    final List<MediaItem> filtered = byMode.where((MediaItem item) {
      if (includeProcessed) {
        return true;
      }
      return !state.decisions.containsKey(item.id);
    }).toList();

    switch (state.discoveryMode) {
      case DiscoveryMode.largestFiles:
        filtered.sort(
          (MediaItem a, MediaItem b) => b.sizeBytes.compareTo(a.sizeBytes),
        );
        break;
      case DiscoveryMode.oldestMedia:
        filtered.sort(
          (MediaItem a, MediaItem b) => a.createdAt.compareTo(b.createdAt),
        );
        break;
      case DiscoveryMode.random:
        return shuffled(filtered, _random);
      default:
        filtered.sort(
          (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
    }

    return filtered;
  }

  List<MediaItem> swipeQueue() {
    return mediaForActiveMode(includeProcessed: false);
  }

  void registerSwipe(
    MediaItem item,
    SwipeDirection direction, {
    List<String> tags = const <String>[],
    String? moveToFolder,
  }) {
    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions);

    int nextFreedBytes = state.currentSessionFreedBytes;

    switch (direction) {
      case SwipeDirection.left:
        nextDecisions[item.id] = SwipeDecision.delete;
        nextFreedBytes += item.sizeBytes;
        break;
      case SwipeDirection.right:
        nextDecisions[item.id] = SwipeDecision.keep;
        break;
      case SwipeDirection.up:
        nextDecisions[item.id] = SwipeDecision.tag;
        break;
      case SwipeDirection.down:
        nextDecisions[item.id] = SwipeDecision.skip;
        break;
    }

    List<MediaItem> nextMedia = state.media;
    if (tags.isNotEmpty || moveToFolder != null) {
      nextMedia = _updateMediaItem(item.id, (MediaItem previous) {
        final Set<String> mergedTags = <String>{
          ...previous.tags,
          ...tags.map((String value) => value.trim()),
        };
        return previous.copyWith(
          tags: mergedTags.where((String value) => value.isNotEmpty).toList(),
          movedToFolder: moveToFolder ?? previous.movedToFolder,
        );
      });
    }

    int lastSessionProcessed = state.lastSessionProcessed;
    int lastSessionFreed = state.lastSessionFreedBytes;
    int sessionsCompleted = state.sessionsCompleted;
    bool showCompletion = false;

    final int currentProcessed = state.currentSessionProcessed + 1;
    final List<MediaItem> pendingAfterAction =
        mediaForMode(state.discoveryMode, source: nextMedia)
            .where(
              (MediaItem mediaItem) => !nextDecisions.containsKey(mediaItem.id),
            )
            .toList();

    if (pendingAfterAction.isEmpty && currentProcessed > 0) {
      showCompletion = true;
      sessionsCompleted += 1;
      lastSessionProcessed = currentProcessed;
      lastSessionFreed = nextFreedBytes;
    }

    state = state.copyWith(
      media: nextMedia,
      decisions: nextDecisions,
      currentSessionProcessed: showCompletion ? 0 : currentProcessed,
      currentSessionFreedBytes: showCompletion ? 0 : nextFreedBytes,
      sessionsCompleted: sessionsCompleted,
      lastSessionProcessed: lastSessionProcessed,
      lastSessionFreedBytes: lastSessionFreed,
      showCompletion: showCompletion,
      clearStatusMessage: true,
    );

    _persist();
  }

  void addCustomTag(String tag) {
    final String normalized = tag.trim();
    if (normalized.isEmpty || state.customTags.contains(normalized)) {
      return;
    }

    state = state.copyWith(
      customTags: <String>[...state.customTags, normalized],
    );
    _persist();
  }

  void tagItem(String mediaId, List<String> tags) {
    final List<String> normalized = tags
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    if (normalized.isEmpty) {
      return;
    }

    final List<MediaItem> updated = _updateMediaItem(mediaId, (MediaItem item) {
      final Set<String> merged = <String>{...item.tags, ...normalized};
      return item.copyWith(tags: merged.toList());
    });

    state = state.copyWith(media: updated);
    _persist();
  }

  void moveItem(String mediaId, String folderName) {
    final String normalized = folderName.trim();
    if (normalized.isEmpty) {
      return;
    }

    final List<MediaItem> updated = _updateMediaItem(mediaId, (MediaItem item) {
      return item.copyWith(movedToFolder: normalized);
    });

    state = state.copyWith(media: updated);
    _persist();
    _attemptMoveAssets(<String>{mediaId}, normalized);
  }

  void dismissCompletion() {
    if (!state.showCompletion) {
      return;
    }

    state = state.copyWith(showCompletion: false);
  }

  List<MediaItem> trashItems() {
    final Set<String> trashIds = state.decisions.entries
        .where(
          (MapEntry<String, SwipeDecision> entry) =>
              entry.value == SwipeDecision.delete,
        )
        .map((MapEntry<String, SwipeDecision> entry) => entry.key)
        .toSet();

    return state.media
        .where((MediaItem item) => trashIds.contains(item.id))
        .toList()
      ..sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt));
  }

  void restoreItems(Set<String> ids) {
    if (ids.isEmpty) {
      return;
    }

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions);
    for (final String id in ids) {
      if (nextDecisions[id] == SwipeDecision.delete) {
        nextDecisions.remove(id);
      }
    }

    final Set<String> nextSelected = Set<String>.from(state.selectedBulkIds)
      ..removeAll(ids);

    state = state.copyWith(
      decisions: nextDecisions,
      selectedBulkIds: nextSelected,
      clearStatusMessage: true,
    );

    _persist();
  }

  Future<void> permanentlyDeleteItems(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final Set<String> idSet = Set<String>.from(ids);
    final List<String> assetIds = state.media
        .where((MediaItem item) => idSet.contains(item.id))
        .map((MediaItem item) => item.assetId)
        .whereType<String>()
        .toList();

    if (assetIds.isNotEmpty) {
      try {
        await PhotoManager.editor.deleteWithIds(assetIds);
      } catch (_) {
        // Index cleanup still proceeds if device delete fails.
      }
    }

    final List<MediaItem> nextMedia = state.media
        .where((MediaItem item) => !idSet.contains(item.id))
        .toList();

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions)..removeWhere(
          (String key, SwipeDecision value) => idSet.contains(key),
        );

    final Set<String> nextSelected = Set<String>.from(state.selectedBulkIds)
      ..removeAll(idSet);

    state = state.copyWith(
      media: nextMedia,
      decisions: nextDecisions,
      selectedBulkIds: nextSelected,
      clearStatusMessage: true,
    );

    _persist();
  }

  void markSelectedForDeletion() {
    if (state.selectedBulkIds.isEmpty) {
      return;
    }

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions);

    for (final String id in state.selectedBulkIds) {
      nextDecisions[id] = SwipeDecision.delete;
    }

    state = state.copyWith(decisions: nextDecisions);
    _persist();
  }

  void bulkAssignTag(String tag) {
    final String normalized = tag.trim();
    if (normalized.isEmpty || state.selectedBulkIds.isEmpty) {
      return;
    }

    List<MediaItem> updated = state.media;
    for (final String id in state.selectedBulkIds) {
      updated = _updateMediaItemFrom(updated, id, (MediaItem item) {
        final Set<String> merged = <String>{...item.tags, normalized};
        return item.copyWith(tags: merged.toList());
      });
    }

    state = state.copyWith(media: updated);
    if (!state.customTags.contains(normalized)) {
      state = state.copyWith(
        customTags: <String>[...state.customTags, normalized],
      );
    }

    _persist();
  }

  void bulkMoveToFolder(String folderName) {
    final String normalized = folderName.trim();
    if (normalized.isEmpty || state.selectedBulkIds.isEmpty) {
      return;
    }

    List<MediaItem> updated = state.media;
    for (final String id in state.selectedBulkIds) {
      updated = _updateMediaItemFrom(
        updated,
        id,
        (MediaItem item) => item.copyWith(movedToFolder: normalized),
      );
    }

    state = state.copyWith(media: updated);
    _persist();
    _attemptMoveAssets(state.selectedBulkIds, normalized);
  }

  void toggleBulkSelection(String mediaId) {
    final Set<String> nextSelection = Set<String>.from(state.selectedBulkIds);
    if (nextSelection.contains(mediaId)) {
      nextSelection.remove(mediaId);
    } else {
      nextSelection.add(mediaId);
    }

    state = state.copyWith(selectedBulkIds: nextSelection);
  }

  void clearBulkSelection() {
    if (state.selectedBulkIds.isEmpty) {
      return;
    }
    state = state.copyWith(selectedBulkIds: <String>{});
  }

  StorageInsights storageInsights() {
    final List<MediaItem> source = state.media;
    final int totalSize = source.fold<int>(
      0,
      (int sum, MediaItem item) => sum + item.sizeBytes,
    );

    final int duplicateCount = source
        .where((MediaItem item) => item.isDuplicate)
        .length;

    final int potentialFreedBytes = trashItems().fold<int>(
      0,
      (int sum, MediaItem item) => sum + item.sizeBytes,
    );

    final List<MediaItem> largestVideos = source
        .where((MediaItem item) => item.kind == MediaKind.video)
        .sorted(
          (MediaItem a, MediaItem b) => b.sizeBytes.compareTo(a.sizeBytes),
        )
        .take(5)
        .toList();

    final Map<String, List<MediaItem>> groupedByFolder =
        groupBy<MediaItem, String>(
          source,
          (MediaItem item) => item.resolvedFolder,
        );

    final List<FolderUsage> folderUsage = groupedByFolder.entries
        .map((MapEntry<String, List<MediaItem>> entry) {
          final int size = entry.value.fold<int>(
            0,
            (int sum, MediaItem item) => sum + item.sizeBytes,
          );
          return FolderUsage(
            folder: entry.key,
            itemCount: entry.value.length,
            totalSizeBytes: size,
          );
        })
        .sorted(
          (FolderUsage a, FolderUsage b) =>
              b.totalSizeBytes.compareTo(a.totalSizeBytes),
        );

    return StorageInsights(
      totalMediaCount: source.length,
      totalSizeBytes: totalSize,
      duplicateCount: duplicateCount,
      potentialFreedBytes: potentialFreedBytes,
      largestVideos: largestVideos,
      folderUsage: folderUsage,
    );
  }

  List<CleanupSuggestion> suggestions() {
    final List<MediaItem> screenshots = mediaForMode(
      DiscoveryMode.screenshots,
      source: state.media,
    );
    final List<MediaItem> largeFiles = mediaForMode(
      DiscoveryMode.largestFiles,
      source: state.media,
    ).take(50).toList();
    final List<MediaItem> oldMedia = mediaForMode(
      DiscoveryMode.oldestMedia,
      source: state.media,
    ).where((MediaItem item) => item.createdAt.year <= 2019).toList();

    return <CleanupSuggestion>[
      CleanupSuggestion(
        title: 'Clean screenshots',
        subtitle: 'Quick win for clutter and storage',
        mode: DiscoveryMode.screenshots,
        itemCount: screenshots.length,
        estimatedBytes: screenshots.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.sizeBytes,
        ),
      ),
      CleanupSuggestion(
        title: 'Large videos',
        subtitle: 'Highest storage impact first',
        mode: DiscoveryMode.largestFiles,
        itemCount: largeFiles.length,
        estimatedBytes: largeFiles.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.sizeBytes,
        ),
      ),
      CleanupSuggestion(
        title: 'Old photos (<=2019)',
        subtitle: 'Rediscover forgotten media',
        mode: DiscoveryMode.oldestMedia,
        itemCount: oldMedia.length,
        estimatedBytes: oldMedia.fold<int>(
          0,
          (int sum, MediaItem item) => sum + item.sizeBytes,
        ),
      ),
    ];
  }

  List<String> folders() {
    return state.media
        .map((MediaItem item) => item.resolvedFolder)
        .toSet()
        .toList()
      ..sort();
  }

  Map<String, List<MediaItem>> taggedCollections() {
    final Map<String, List<MediaItem>> collections =
        <String, List<MediaItem>>{};

    for (final MediaItem item in state.media) {
      for (final String tag in item.tags) {
        collections.putIfAbsent(tag, () => <MediaItem>[]).add(item);
      }
    }

    final List<String> keys = collections.keys.toList()..sort();
    return <String, List<MediaItem>>{
      for (final String key in keys)
        key: collections[key]!
          ..sort(
            (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
          ),
    };
  }

  List<MediaItem> mediaForMode(
    DiscoveryMode mode, {
    required List<MediaItem> source,
  }) {
    return _mediaByMode(mode, source: source).toList();
  }

  Iterable<MediaItem> _mediaByMode(
    DiscoveryMode mode, {
    List<MediaItem>? source,
  }) {
    final List<MediaItem> pool = source ?? state.media;

    switch (mode) {
      case DiscoveryMode.all:
        return pool;
      case DiscoveryMode.largestFiles:
        return pool;
      case DiscoveryMode.oldestMedia:
        return pool;
      case DiscoveryMode.random:
        return pool;
      case DiscoveryMode.duplicates:
        return pool.where((MediaItem item) => item.isDuplicate);
      case DiscoveryMode.screenshots:
        return pool.where(
          (MediaItem item) =>
              item.resolvedFolder.toLowerCase().contains('screenshot'),
        );
      case DiscoveryMode.whatsapp:
        return pool.where(
          (MediaItem item) =>
              item.resolvedFolder.toLowerCase().contains('whatsapp'),
        );
      case DiscoveryMode.cameraRoll:
        return pool.where((MediaItem item) {
          final String folder = item.resolvedFolder.toLowerCase();
          return folder.contains('camera') || folder.contains('dcim');
        });
      case DiscoveryMode.downloads:
        return pool.where(
          (MediaItem item) =>
              item.resolvedFolder.toLowerCase().contains('download'),
        );
      case DiscoveryMode.specificFolder:
        if (state.specificFolder == null ||
            state.specificFolder!.trim().isEmpty) {
          return pool;
        }
        return pool.where(
          (MediaItem item) =>
              item.resolvedFolder.toLowerCase() ==
              state.specificFolder!.toLowerCase(),
        );
    }
  }

  DiscoveryMode _modeForScope(ScanScope scope) {
    switch (scope) {
      case ScanScope.entireGallery:
        return DiscoveryMode.all;
      case ScanScope.specificFolder:
        return DiscoveryMode.specificFolder;
      case ScanScope.cameraRollOnly:
        return DiscoveryMode.cameraRoll;
      case ScanScope.whatsappMedia:
        return DiscoveryMode.whatsapp;
      case ScanScope.screenshots:
        return DiscoveryMode.screenshots;
      case ScanScope.downloads:
        return DiscoveryMode.downloads;
    }
  }

  List<MediaItem> _updateMediaItem(
    String mediaId,
    MediaItem Function(MediaItem previous) transform,
  ) {
    return _updateMediaItemFrom(state.media, mediaId, transform);
  }

  List<MediaItem> _updateMediaItemFrom(
    List<MediaItem> source,
    String mediaId,
    MediaItem Function(MediaItem previous) transform,
  ) {
    return source.map((MediaItem item) {
      if (item.id != mediaId) {
        return item;
      }
      return transform(item);
    }).toList();
  }

  Future<void> _persist() async {
    await _store.saveState(state.toJson());
  }

  Future<void> _attemptMoveAssets(Set<String> ids, String folderName) async {
    final List<String> assetIds = state.media
        .where((MediaItem item) => ids.contains(item.id))
        .map((MediaItem item) => item.assetId)
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
}
