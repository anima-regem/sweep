import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gallery_index_store.dart';
import '../data/gallery_repository.dart';
import '../data/gallery_scanner.dart';
import '../data/user_action_store.dart';
import '../models/sweep_models.dart';

final Provider<GalleryScanner> galleryScannerProvider =
    Provider<GalleryScanner>((Ref ref) {
      return const GalleryScanner();
    });

final Provider<GalleryIndexStore> galleryIndexStoreProvider =
    Provider<GalleryIndexStore>((Ref ref) {
      return GalleryIndexStore();
    });

final Provider<UserActionStore> userActionStoreProvider =
    Provider<UserActionStore>((Ref ref) {
      return UserActionStore();
    });

final Provider<GalleryRepository> galleryRepositoryProvider =
    Provider<GalleryRepository>((Ref ref) {
      return LocalGalleryRepository(
        scanner: ref.read(galleryScannerProvider),
        galleryStore: ref.read(galleryIndexStoreProvider),
        userStore: ref.read(userActionStoreProvider),
      );
    });

final StateNotifierProvider<SweepController, SweepState>
sweepControllerProvider = StateNotifierProvider<SweepController, SweepState>((
  Ref ref,
) {
  final SweepController controller = SweepController(
    repository: ref.read(galleryRepositoryProvider),
  );
  controller.initialize();
  return controller;
});

class SweepState {
  const SweepState({
    required this.isLoading,
    required this.initialized,
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
    required this.summary,
    required this.scanProgress,
    required this.activePage,
    required this.trashPage,
    required this.sessionQueue,
    required this.folders,
    required this.taggedCollections,
    required this.cleanupSuggestions,
    required this.randomSeed,
  });

  factory SweepState.initial() {
    return SweepState(
      isLoading: false,
      initialized: false,
      discoveryMode: DiscoveryMode.all,
      scanScope: ScanScope.entireGallery,
      specificFolder: null,
      decisions: const <String, SwipeDecision>{},
      selectedBulkIds: const <String>{},
      customTags: const <String>[
        'Friends',
        'Work',
        'Travel',
        'Family',
        'Documents',
      ],
      sessionsCompleted: 0,
      currentSessionProcessed: 0,
      currentSessionFreedBytes: 0,
      lastSessionProcessed: 0,
      lastSessionFreedBytes: 0,
      showCompletion: false,
      statusMessage: null,
      summary: const GallerySummary.empty(),
      scanProgress: const ScanProgress.idle(),
      activePage: const GalleryPage(),
      trashPage: const GalleryPage(),
      sessionQueue: const <MediaItem>[],
      folders: const <String>[],
      taggedCollections: const <String, List<MediaItem>>{},
      cleanupSuggestions: const <CleanupSuggestion>[],
      randomSeed: 73,
    );
  }

  final bool isLoading;
  final bool initialized;
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
  final GallerySummary summary;
  final ScanProgress scanProgress;
  final GalleryPage activePage;
  final GalleryPage trashPage;
  final List<MediaItem> sessionQueue;
  final List<String> folders;
  final Map<String, List<MediaItem>> taggedCollections;
  final List<CleanupSuggestion> cleanupSuggestions;
  final int randomSeed;

  SweepState copyWith({
    bool? isLoading,
    bool? initialized,
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
    GallerySummary? summary,
    ScanProgress? scanProgress,
    GalleryPage? activePage,
    GalleryPage? trashPage,
    List<MediaItem>? sessionQueue,
    List<String>? folders,
    Map<String, List<MediaItem>>? taggedCollections,
    List<CleanupSuggestion>? cleanupSuggestions,
    int? randomSeed,
  }) {
    return SweepState(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
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
      summary: summary ?? this.summary,
      scanProgress: scanProgress ?? this.scanProgress,
      activePage: activePage ?? this.activePage,
      trashPage: trashPage ?? this.trashPage,
      sessionQueue: sessionQueue ?? this.sessionQueue,
      folders: folders ?? this.folders,
      taggedCollections: taggedCollections ?? this.taggedCollections,
      cleanupSuggestions: cleanupSuggestions ?? this.cleanupSuggestions,
      randomSeed: randomSeed ?? this.randomSeed,
    );
  }
}

class SweepController extends StateNotifier<SweepState> {
  SweepController({required GalleryRepository repository})
    : _repository = repository,
      _random = Random(),
      super(SweepState.initial());

  static const int _explorePageSize = 24;
  static const int _trashPageSize = 36;
  static const int _sessionQueueSize = 16;

  final GalleryRepository _repository;
  final Random _random;

  Future<void> initialize() async {
    if (state.initialized) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      statusMessage: 'Loading gallery index...',
    );

    final RepositoryBootstrap bootstrap = await _repository.initialize();
    final int randomSeed = _random.nextInt(1 << 30);

    state = state.copyWith(
      isLoading: false,
      initialized: true,
      discoveryMode: bootstrap.discoveryMode,
      scanScope: bootstrap.scanScope,
      specificFolder: bootstrap.specificFolder,
      decisions: bootstrap.decisions,
      customTags: bootstrap.customTags,
      sessionsCompleted: bootstrap.sessionsCompleted,
      lastSessionProcessed: bootstrap.lastSessionProcessed,
      lastSessionFreedBytes: bootstrap.lastSessionFreedBytes,
      summary: bootstrap.summary,
      folders: bootstrap.folders,
      cleanupSuggestions: _repository.suggestions(),
      randomSeed: randomSeed,
      statusMessage: bootstrap.hasIndexedMedia
          ? 'Gallery index ready'
          : 'Indexing gallery...',
    );

    _refreshLoadedViews(resetActivePage: true, resetTrashPage: true);

    if (!bootstrap.hasIndexedMedia) {
      unawaited(scanGallery(scope: state.scanScope));
    }
  }

  Future<void> scanGallery({ScanScope? scope, String? specificFolder}) async {
    final ScanScope selectedScope = scope ?? state.scanScope;
    final DiscoveryMode defaultMode = _modeForScope(selectedScope);
    final String? nextFolder = selectedScope == ScanScope.specificFolder
        ? specificFolder
        : state.specificFolder;

    state = state.copyWith(
      isLoading: true,
      statusMessage: 'Scanning gallery... (${selectedScope.label})',
      scanScope: selectedScope,
      discoveryMode: defaultMode,
      specificFolder: nextFolder,
      clearSpecificFolder: selectedScope != ScanScope.specificFolder,
      selectedBulkIds: <String>{},
      currentSessionProcessed: 0,
      currentSessionFreedBytes: 0,
      showCompletion: false,
    );
    await _persistPreferences();
    _refreshLoadedViews(resetActivePage: true, resetTrashPage: false);

    unawaited(
      _repository.startScan(
        scope: selectedScope,
        specificFolder: nextFolder,
        onProgress: _handleScanProgress,
        onDataChanged: () {
          _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
        },
      ),
    );
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
      randomSeed: mode == DiscoveryMode.random
          ? _random.nextInt(1 << 30)
          : state.randomSeed,
    );

    unawaited(_persistPreferences());
    _refreshLoadedViews(resetActivePage: true, resetTrashPage: false);
  }

  Future<void> loadMoreActiveMedia() async {
    if (!state.activePage.hasMore) {
      return;
    }

    _refreshActivePage(targetCount: state.activePage.items.length + _explorePageSize);
  }

  Future<void> loadMoreTrashItems() async {
    if (!state.trashPage.hasMore) {
      return;
    }

    _refreshTrashPage(targetCount: state.trashPage.items.length + _trashPageSize);
  }

  List<MediaItem> swipeQueue() => state.sessionQueue;

  List<MediaItem> trashItems() => state.trashPage.items;

  List<String> folders() => state.folders;

  Map<String, List<MediaItem>> taggedCollections() => state.taggedCollections;

  GallerySummary storageInsights() => state.summary;

  List<CleanupSuggestion> suggestions() => state.cleanupSuggestions;

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
        nextFreedBytes += item.safeSizeBytes;
        _repository.setDecision(item.id, SwipeDecision.delete);
        break;
      case SwipeDirection.right:
        nextDecisions[item.id] = SwipeDecision.keep;
        _repository.setDecision(item.id, SwipeDecision.keep);
        break;
      case SwipeDirection.up:
        nextDecisions[item.id] = SwipeDecision.tag;
        _repository.setDecision(item.id, SwipeDecision.tag);
        break;
      case SwipeDirection.down:
        nextDecisions[item.id] = SwipeDecision.skip;
        _repository.setDecision(item.id, SwipeDecision.skip);
        break;
    }

    if (tags.isNotEmpty) {
      _repository.applyTags(item.id, tags);
    }
    if (moveToFolder != null) {
      _repository.applyMove(item.id, moveToFolder);
      unawaited(_repository.moveAssets(<String>{item.id}, moveToFolder));
    }

    final int currentProcessed = state.currentSessionProcessed + 1;
    final List<MediaItem> pendingAfterAction = _repository.fetchQueue(
      mode: state.discoveryMode,
      specificFolder: state.specificFolder,
      limit: 1,
      randomSeed: state.randomSeed,
    );

    bool showCompletion = false;
    int sessionsCompleted = state.sessionsCompleted;
    int lastSessionProcessed = state.lastSessionProcessed;
    int lastSessionFreed = state.lastSessionFreedBytes;

    if (pendingAfterAction.isEmpty && currentProcessed > 0) {
      showCompletion = true;
      sessionsCompleted += 1;
      lastSessionProcessed = currentProcessed;
      lastSessionFreed = nextFreedBytes;
    }

    state = state.copyWith(
      decisions: nextDecisions,
      currentSessionProcessed: showCompletion ? 0 : currentProcessed,
      currentSessionFreedBytes: showCompletion ? 0 : nextFreedBytes,
      sessionsCompleted: sessionsCompleted,
      lastSessionProcessed: lastSessionProcessed,
      lastSessionFreedBytes: lastSessionFreed,
      showCompletion: showCompletion,
      clearStatusMessage: true,
    );
    unawaited(_persistPreferences());
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void addCustomTag(String tag) {
    final String normalized = tag.trim();
    if (normalized.isEmpty || state.customTags.contains(normalized)) {
      return;
    }

    _repository.addCustomTag(normalized);
    state = state.copyWith(customTags: <String>[...state.customTags, normalized]);
    unawaited(_persistPreferences());
  }

  void tagItem(String mediaId, List<String> tags) {
    if (tags.isEmpty) {
      return;
    }
    _repository.applyTags(mediaId, tags);
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void moveItem(String mediaId, String folderName) {
    final String normalized = folderName.trim();
    if (normalized.isEmpty) {
      return;
    }

    _repository.applyMove(mediaId, normalized);
    unawaited(_repository.moveAssets(<String>{mediaId}, normalized));
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void dismissCompletion() {
    if (!state.showCompletion) {
      return;
    }

    state = state.copyWith(showCompletion: false);
  }

  void restoreItems(Set<String> ids) {
    if (ids.isEmpty) {
      return;
    }

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions);
    for (final String id in ids) {
      nextDecisions.remove(id);
      _repository.clearDecision(id);
    }

    final Set<String> nextSelected = Set<String>.from(state.selectedBulkIds)
      ..removeAll(ids);

    state = state.copyWith(
      decisions: nextDecisions,
      selectedBulkIds: nextSelected,
      clearStatusMessage: true,
    );
    unawaited(_persistPreferences());
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  Future<void> permanentlyDeleteItems(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await _repository.permanentlyDeleteItems(ids);

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions)
          ..removeWhere((String key, SwipeDecision value) => ids.contains(key));

    final Set<String> nextSelected = Set<String>.from(state.selectedBulkIds)
      ..removeAll(ids);

    state = state.copyWith(
      decisions: nextDecisions,
      selectedBulkIds: nextSelected,
      clearStatusMessage: true,
    );
    await _persistPreferences();
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void markSelectedForDeletion() {
    if (state.selectedBulkIds.isEmpty) {
      return;
    }

    final Map<String, SwipeDecision> nextDecisions =
        Map<String, SwipeDecision>.from(state.decisions);
    for (final String id in state.selectedBulkIds) {
      nextDecisions[id] = SwipeDecision.delete;
      _repository.setDecision(id, SwipeDecision.delete);
    }

    state = state.copyWith(decisions: nextDecisions);
    unawaited(_persistPreferences());
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void bulkAssignTag(String tag) {
    final String normalized = tag.trim();
    if (normalized.isEmpty || state.selectedBulkIds.isEmpty) {
      return;
    }

    for (final String id in state.selectedBulkIds) {
      _repository.applyTags(id, <String>[normalized]);
    }
    if (!state.customTags.contains(normalized)) {
      _repository.addCustomTag(normalized);
      state = state.copyWith(customTags: <String>[...state.customTags, normalized]);
    }

    unawaited(_persistPreferences());
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
  }

  void bulkMoveToFolder(String folderName) {
    final String normalized = folderName.trim();
    if (normalized.isEmpty || state.selectedBulkIds.isEmpty) {
      return;
    }

    for (final String id in state.selectedBulkIds) {
      _repository.applyMove(id, normalized);
    }
    unawaited(_repository.moveAssets(state.selectedBulkIds, normalized));
    _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
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

  void _handleScanProgress(ScanProgress progress) {
    state = state.copyWith(
      isLoading: progress.isRunning,
      scanProgress: progress,
      statusMessage:
          '${progress.label} • ${progress.indexedCount} indexed'
          '${progress.enrichedCount > 0 ? ' • ${progress.enrichedCount} refined' : ''}',
      summary: _repository.summary,
      folders: _repository.folders,
      cleanupSuggestions: _repository.suggestions(),
    );
  }

  void _refreshLoadedViews({
    required bool resetActivePage,
    required bool resetTrashPage,
  }) {
    _refreshSummary();
    _refreshActivePage(
      targetCount: resetActivePage
          ? _explorePageSize
          : max(_explorePageSize, state.activePage.items.length),
    );
    _refreshSessionQueue();
    _refreshTrashPage(
      targetCount: resetTrashPage
          ? _trashPageSize
          : max(_trashPageSize, state.trashPage.items.length),
    );
    _refreshCollections();
  }

  void _refreshSummary() {
    state = state.copyWith(
      summary: _repository.summary,
      folders: _repository.folders,
      cleanupSuggestions: _repository.suggestions(),
    );
  }

  void _refreshActivePage({required int targetCount}) {
    final GalleryPage page = _repository.fetchPage(
      mode: state.discoveryMode,
      specificFolder: state.specificFolder,
      offset: 0,
      limit: targetCount,
      includeProcessed: true,
      randomSeed: state.randomSeed,
    );
    _repository.prioritizeForEnrichment(
      page.items.map((MediaItem item) => item.id),
      onProgress: _handleScanProgress,
      onDataChanged: () {
        _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
      },
    );
    state = state.copyWith(activePage: page);
  }

  void _refreshSessionQueue() {
    final List<MediaItem> queue = _repository.fetchQueue(
      mode: state.discoveryMode,
      specificFolder: state.specificFolder,
      limit: _sessionQueueSize,
      randomSeed: state.randomSeed,
    );
    _repository.prioritizeForEnrichment(
      queue.map((MediaItem item) => item.id),
      onProgress: _handleScanProgress,
      onDataChanged: () {
        _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
      },
    );
    state = state.copyWith(sessionQueue: queue);
  }

  void _refreshTrashPage({required int targetCount}) {
    final GalleryPage page = _repository.fetchTrashPage(
      offset: 0,
      limit: targetCount,
    );
    _repository.prioritizeForEnrichment(
      page.items.map((MediaItem item) => item.id),
      onProgress: _handleScanProgress,
      onDataChanged: () {
        _refreshLoadedViews(resetActivePage: false, resetTrashPage: false);
      },
    );
    state = state.copyWith(trashPage: page);
  }

  void _refreshCollections() {
    state = state.copyWith(
      taggedCollections: _repository.taggedCollections(previewLimit: 15),
    );
  }

  Future<void> _persistPreferences() {
    return _repository.persistPreferences(
      discoveryMode: state.discoveryMode,
      scanScope: state.scanScope,
      specificFolder: state.specificFolder,
      customTags: state.customTags,
      sessionsCompleted: state.sessionsCompleted,
      lastSessionProcessed: state.lastSessionProcessed,
      lastSessionFreedBytes: state.lastSessionFreedBytes,
    );
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
}
