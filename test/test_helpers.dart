import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:sweep/app/sweep_app.dart';
import 'package:sweep/app/theme.dart';
import 'package:sweep/data/gallery_repository.dart';
import 'package:sweep/models/sweep_models.dart';
import 'package:sweep/state/sweep_controller.dart';
import 'package:sweep/ui/shell/shell_controller.dart';

List<MediaItem> buildFixedMedia() {
  return <MediaItem>[
    MediaItem(
      id: 'camera_1',
      assetId: null,
      path: '/mock/Camera/img_001.jpg',
      sizeBytes: 4 * 1024 * 1024,
      width: 1080,
      height: 1440,
      kind: MediaKind.image,
      createdAt: DateTime(2025, 1, 4),
      folder: 'Camera',
      duplicateStatus: DuplicateStatus.unique,
    ),
    MediaItem(
      id: 'camera_2',
      assetId: null,
      path: '/mock/Camera/img_002.jpg',
      sizeBytes: 3 * 1024 * 1024,
      width: 1080,
      height: 1440,
      kind: MediaKind.livePhoto,
      createdAt: DateTime(2024, 10, 12),
      folder: 'Camera',
      duplicateStatus: DuplicateStatus.unique,
      tags: <String>['Family'],
    ),
    MediaItem(
      id: 'download_1',
      assetId: null,
      path: '/mock/Downloads/receipt.png',
      sizeBytes: 900 * 1024,
      width: 1280,
      height: 720,
      kind: MediaKind.image,
      createdAt: DateTime(2023, 7, 18),
      folder: 'Downloads',
      duplicateStatus: DuplicateStatus.unique,
      tags: <String>['Documents'],
    ),
    MediaItem(
      id: 'screenshot_1',
      assetId: null,
      path: '/mock/Screenshots/shot_001.png',
      sizeBytes: 800 * 1024,
      width: 1280,
      height: 720,
      kind: MediaKind.image,
      createdAt: DateTime(2022, 9, 3),
      folder: 'Screenshots',
      duplicateStatus: DuplicateStatus.duplicate,
    ),
    MediaItem(
      id: 'video_1',
      assetId: null,
      path: '/mock/Travel/clip_001.mp4',
      sizeBytes: 24 * 1024 * 1024,
      width: 1920,
      height: 1080,
      kind: MediaKind.video,
      createdAt: DateTime(2021, 3, 8),
      folder: 'Travel',
      duplicateStatus: DuplicateStatus.unique,
      durationSeconds: 42,
      tags: <String>['Travel'],
    ),
    MediaItem(
      id: 'video_2',
      assetId: null,
      path: '/mock/WhatsApp Video/clip_002.mp4',
      sizeBytes: 16 * 1024 * 1024,
      width: 1920,
      height: 1080,
      kind: MediaKind.video,
      createdAt: DateTime(2019, 11, 1),
      folder: 'WhatsApp Video',
      duplicateStatus: DuplicateStatus.unique,
      durationSeconds: 63,
    ),
    MediaItem(
      id: 'work_1',
      assetId: null,
      path: '/mock/Work/doc_001.png',
      sizeBytes: 2 * 1024 * 1024,
      width: 1024,
      height: 1024,
      kind: MediaKind.burst,
      createdAt: DateTime(2018, 2, 14),
      folder: 'Work',
      duplicateStatus: DuplicateStatus.unique,
      tags: <String>['Work'],
    ),
    MediaItem(
      id: 'family_1',
      assetId: null,
      path: '/mock/Family/img_003.jpg',
      sizeBytes: 5 * 1024 * 1024,
      width: 1080,
      height: 1350,
      kind: MediaKind.image,
      createdAt: DateTime(2017, 6, 30),
      folder: 'Family',
      duplicateStatus: DuplicateStatus.unique,
      tags: <String>['Family'],
    ),
  ];
}

SweepState buildSeededState({
  List<MediaItem>? media,
  DiscoveryMode discoveryMode = DiscoveryMode.all,
  ScanScope scanScope = ScanScope.entireGallery,
  String? specificFolder,
  Map<String, SwipeDecision>? decisions,
  Set<String>? selectedBulkIds,
  List<String>? customTags,
  int sessionsCompleted = 3,
  int lastSessionProcessed = 14,
  int lastSessionFreedBytes = 11 * 1024 * 1024,
}) {
  final List<MediaItem> fixedMedia = media ?? buildFixedMedia();
  final Map<String, SwipeDecision> seededDecisions =
      decisions ?? <String, SwipeDecision>{};
  final List<String> seededTags =
      customTags ??
      const <String>[
        'Friends',
        'Work',
        'Travel',
        'Family',
        'Documents',
      ];
  final GallerySummary summary = _summaryFor(fixedMedia, seededDecisions);

  return SweepState(
    isLoading: false,
    initialized: true,
    discoveryMode: discoveryMode,
    scanScope: scanScope,
    specificFolder: specificFolder,
    decisions: seededDecisions,
    selectedBulkIds: selectedBulkIds ?? <String>{},
    customTags: seededTags,
    sessionsCompleted: sessionsCompleted,
    currentSessionProcessed: 0,
    currentSessionFreedBytes: 0,
    lastSessionProcessed: lastSessionProcessed,
    lastSessionFreedBytes: lastSessionFreedBytes,
    showCompletion: false,
    statusMessage: null,
    summary: summary,
    scanProgress: const ScanProgress.idle(),
    activePage: _pageFor(
      media: fixedMedia,
      discoveryMode: discoveryMode,
      specificFolder: specificFolder,
      decisions: seededDecisions,
      limit: 24,
      includeProcessed: true,
      randomSeed: 73,
    ),
    trashPage: GalleryPage(
      items: fixedMedia
          .where((MediaItem item) => seededDecisions[item.id] == SwipeDecision.delete)
          .toList()
        ..sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt)),
      offset: 0,
      hasMore: false,
      totalCount: seededDecisions.values
          .where((SwipeDecision decision) => decision == SwipeDecision.delete)
          .length,
    ),
    sessionQueue: _pageFor(
      media: fixedMedia,
      discoveryMode: discoveryMode,
      specificFolder: specificFolder,
      decisions: seededDecisions,
      limit: 16,
      includeProcessed: false,
      randomSeed: 73,
    ).items,
    folders: (fixedMedia.map((MediaItem item) => item.resolvedFolder).toSet().toList()
      ..sort()),
    taggedCollections: _tagCollections(fixedMedia),
    cleanupSuggestions: _suggestionsFor(fixedMedia),
    randomSeed: 73,
  );
}

class TestGalleryRepository implements GalleryRepository {
  TestGalleryRepository(this._state) {
    _media = <String, MediaItem>{
      for (final MediaItem item in [
        ..._state.activePage.items,
        ..._state.sessionQueue,
        ..._state.trashPage.items,
        ..._state.taggedCollections.values.expand((List<MediaItem> value) => value),
      ])
        item.id: item,
    };
    for (final MediaItem item in buildFixedMedia()) {
      _media.putIfAbsent(item.id, () => item);
    }
    _decisions = Map<String, SwipeDecision>.from(_state.decisions);
    _customTags = List<String>.from(_state.customTags);
    _discoveryMode = _state.discoveryMode;
    _scanScope = _state.scanScope;
    _specificFolder = _state.specificFolder;
    _sessionsCompleted = _state.sessionsCompleted;
    _lastSessionProcessed = _state.lastSessionProcessed;
    _lastSessionFreedBytes = _state.lastSessionFreedBytes;
  }

  final SweepState _state;
  late Map<String, MediaItem> _media;
  late Map<String, SwipeDecision> _decisions;
  late List<String> _customTags;
  late DiscoveryMode _discoveryMode;
  late ScanScope _scanScope;
  late String? _specificFolder;
  late int _sessionsCompleted;
  late int _lastSessionProcessed;
  late int _lastSessionFreedBytes;

  @override
  Future<RepositoryBootstrap> initialize() async {
    return RepositoryBootstrap(
      discoveryMode: _discoveryMode,
      scanScope: _scanScope,
      specificFolder: _specificFolder,
      customTags: _customTags,
      decisions: _decisions,
      sessionsCompleted: _sessionsCompleted,
      lastSessionProcessed: _lastSessionProcessed,
      lastSessionFreedBytes: _lastSessionFreedBytes,
      summary: summary,
      folders: folders,
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
    return _pageFor(
      media: _media.values.toList(),
      discoveryMode: mode,
      specificFolder: specificFolder,
      decisions: _decisions,
      limit: limit,
      includeProcessed: includeProcessed,
      randomSeed: randomSeed,
      offset: offset,
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
    final List<MediaItem> trash = _media.values
        .where((MediaItem item) => _decisions[item.id] == SwipeDecision.delete)
        .toList()
      ..sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt));
    final int safeOffset = offset.clamp(0, trash.length);
    final int end = safeOffset + limit > trash.length
        ? trash.length
        : safeOffset + limit;
    return GalleryPage(
      items: trash.sublist(safeOffset, end),
      offset: safeOffset,
      hasMore: end < trash.length,
      totalCount: trash.length,
    );
  }

  @override
  Map<String, List<MediaItem>> taggedCollections({required int previewLimit}) {
    return _tagCollections(_media.values.toList(), previewLimit: previewLimit);
  }

  @override
  GallerySummary get summary => _summaryFor(_media.values.toList(), _decisions);

  @override
  List<String> get folders =>
      _media.values.map((MediaItem item) => item.resolvedFolder).toSet().toList()
        ..sort();

  @override
  List<CleanupSuggestion> suggestions() {
    return _suggestionsFor(_media.values.toList());
  }

  @override
  bool get hasIndexedMedia => _media.isNotEmpty;

  @override
  Future<void> startScan({
    required ScanScope scope,
    required String? specificFolder,
    required void Function(ScanProgress progress) onProgress,
    required VoidCallback onDataChanged,
  }) async {
    onProgress(
      ScanProgress(
        isRunning: false,
        indexedCount: _media.length,
        enrichedCount: _media.length,
        label: 'Test repository ready',
      ),
    );
  }

  @override
  void prioritizeForEnrichment(
    Iterable<String> ids, {
    void Function(ScanProgress progress)? onProgress,
    VoidCallback? onDataChanged,
  }) {}

  @override
  void setDecision(String mediaId, SwipeDecision decision) {
    _decisions[mediaId] = decision;
  }

  @override
  void clearDecision(String mediaId) {
    _decisions.remove(mediaId);
  }

  @override
  void addCustomTag(String tag) {
    if (!_customTags.contains(tag)) {
      _customTags = <String>[..._customTags, tag];
    }
  }

  @override
  void applyTags(String mediaId, List<String> tags) {
    final MediaItem? item = _media[mediaId];
    if (item == null) {
      return;
    }
    _media[mediaId] = item.copyWith(
      tags: <String>{...item.tags, ...tags}.toList(),
    );
  }

  @override
  void applyMove(String mediaId, String folderName) {
    final MediaItem? item = _media[mediaId];
    if (item == null) {
      return;
    }
    _media[mediaId] = item.copyWith(movedToFolder: folderName);
  }

  @override
  Future<void> permanentlyDeleteItems(Set<String> ids) async {
    _media.removeWhere((String key, MediaItem value) => ids.contains(key));
    _decisions.removeWhere((String key, SwipeDecision value) => ids.contains(key));
  }

  @override
  Future<void> moveAssets(Set<String> ids, String folderName) async {}

  @override
  Future<void> persistPreferences({
    required DiscoveryMode discoveryMode,
    required ScanScope scanScope,
    required String? specificFolder,
    required List<String> customTags,
    required int sessionsCompleted,
    required int lastSessionProcessed,
    required int lastSessionFreedBytes,
  }) async {
    _discoveryMode = discoveryMode;
    _scanScope = scanScope;
    _specificFolder = specificFolder;
    _customTags = customTags;
    _sessionsCompleted = sessionsCompleted;
    _lastSessionProcessed = lastSessionProcessed;
    _lastSessionFreedBytes = lastSessionFreedBytes;
  }
}

class TestShellController extends SweepShellController {
  TestShellController(SweepDestination destination) : super() {
    state = destination;
  }
}

class TestSweepController extends SweepController {
  TestSweepController(SweepState initialState)
    : super(repository: TestGalleryRepository(initialState)) {
      state = initialState;
    }

  @override
  Future<void> initialize() async {}
}

Future<void> pumpSweepApp(
  WidgetTester tester, {
  Brightness brightness = Brightness.dark,
  SweepDestination destination = SweepDestination.session,
  SweepState? seededState,
  List<MediaItem>? media,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final List<MediaItem> fixedMedia = media ?? buildFixedMedia();
  final SweepState state = seededState ?? buildSeededState(media: fixedMedia);

  await tester.pumpWidget(
    _buildScopedWidget(
      state: state,
      child: const SweepApp(),
      destination: destination,
    ),
  );
  await settleSweep(tester);
}

Future<void> pumpScopedSweepWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  SweepDestination destination = SweepDestination.session,
  SweepState? seededState,
  List<MediaItem>? media,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final List<MediaItem> fixedMedia = media ?? buildFixedMedia();
  final SweepState state = seededState ?? buildSeededState(media: fixedMedia);

  await tester.pumpWidget(
    _buildScopedWidget(
      state: state,
      destination: destination,
      child: WidgetsApp(
        color: const Color(0xFF05070C),
        pageRouteBuilder:
            <T>(RouteSettings settings, WidgetBuilder builder) =>
                PageRouteBuilder<T>(
                  settings: settings,
                  pageBuilder:
                      (
                        BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                      ) => builder(context),
                ),
        home: SweepThemeHost(child: child),
      ),
    ),
  );

  await settleSweep(tester);
}

Widget _buildScopedWidget({
  required SweepState state,
  required Widget child,
  required SweepDestination destination,
}) {
  return ProviderScope(
    overrides: <Override>[
      sweepControllerProvider.overrideWith(
        (Ref ref) => TestSweepController(state),
      ),
      sweepShellControllerProvider.overrideWith(
        (Ref ref) => TestShellController(destination),
      ),
    ],
    child: child,
  );
}

GallerySummary _summaryFor(
  List<MediaItem> media,
  Map<String, SwipeDecision> decisions,
) {
  final int totalBytes = media.fold<int>(
    0,
    (int sum, MediaItem item) => sum + item.safeSizeBytes,
  );
  final int duplicateCount = media.where((MediaItem item) => item.isDuplicate).length;
  final int potentialFreedBytes = media
      .where((MediaItem item) => decisions[item.id] == SwipeDecision.delete)
      .fold<int>(0, (int sum, MediaItem item) => sum + item.safeSizeBytes);
  final List<MediaItem> largestVideos = media
      .where((MediaItem item) => item.kind == MediaKind.video)
      .toList()
    ..sort((MediaItem a, MediaItem b) => b.safeSizeBytes.compareTo(a.safeSizeBytes));
  final Map<String, FolderUsage> folderMap = <String, FolderUsage>{};
  for (final MediaItem item in media) {
    final FolderUsage? existing = folderMap[item.resolvedFolder];
    folderMap[item.resolvedFolder] = FolderUsage(
      folder: item.resolvedFolder,
      itemCount: (existing?.itemCount ?? 0) + 1,
      totalSizeBytes: (existing?.totalSizeBytes ?? 0) + item.safeSizeBytes,
    );
  }

  return GallerySummary(
    totalMediaCount: media.length,
    totalSizeBytes: totalBytes,
    duplicateCount: duplicateCount,
    potentialFreedBytes: potentialFreedBytes,
    largestVideos: largestVideos.take(5).toList(),
    folderUsage: folderMap.values.toList(),
    unresolvedSizeCount: media.where((MediaItem item) => item.sizeBytes == null).length,
    isPartial: media.any((MediaItem item) => item.sizeBytes == null),
  );
}

GalleryPage _pageFor({
  required List<MediaItem> media,
  required DiscoveryMode discoveryMode,
  required String? specificFolder,
  required Map<String, SwipeDecision> decisions,
  required int limit,
  required bool includeProcessed,
  required int randomSeed,
  int offset = 0,
}) {
  final List<MediaItem> filtered = media.where((MediaItem item) {
    if (!includeProcessed && decisions.containsKey(item.id)) {
      return false;
    }
    return _matchesMode(item, discoveryMode, specificFolder);
  }).toList();

  switch (discoveryMode) {
    case DiscoveryMode.largestFiles:
      filtered.sort((MediaItem a, MediaItem b) => b.safeSizeBytes.compareTo(a.safeSizeBytes));
      break;
    case DiscoveryMode.oldestMedia:
      filtered.sort((MediaItem a, MediaItem b) => a.createdAt.compareTo(b.createdAt));
      break;
    case DiscoveryMode.random:
      filtered.sort((MediaItem a, MediaItem b) {
        return Object.hash(a.id, randomSeed).compareTo(Object.hash(b.id, randomSeed));
      });
      break;
    default:
      filtered.sort((MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt));
      break;
  }

  final int safeOffset = offset.clamp(0, filtered.length);
  final int end = safeOffset + limit > filtered.length
      ? filtered.length
      : safeOffset + limit;

  return GalleryPage(
    items: filtered.sublist(safeOffset, end),
    offset: safeOffset,
    hasMore: end < filtered.length,
    totalCount: filtered.length,
  );
}

bool _matchesMode(
  MediaItem item,
  DiscoveryMode discoveryMode,
  String? specificFolder,
) {
  final String folder = item.resolvedFolder.toLowerCase();
  switch (discoveryMode) {
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
      return folder.contains('camera');
    case DiscoveryMode.downloads:
      return folder.contains('download');
    case DiscoveryMode.specificFolder:
      if (specificFolder == null || specificFolder.isEmpty) {
        return true;
      }
      return folder == specificFolder.toLowerCase();
  }
}

Map<String, List<MediaItem>> _tagCollections(
  List<MediaItem> media, {
  int previewLimit = 15,
}) {
  final Map<String, List<MediaItem>> output = <String, List<MediaItem>>{};
  for (final MediaItem item in media) {
    for (final String tag in item.tags) {
      output.putIfAbsent(tag, () => <MediaItem>[]).add(item);
    }
  }

  return <String, List<MediaItem>>{
    for (final String key in output.keys.toList()..sort())
      key: (output[key]!..sort(
            (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
          ))
          .take(previewLimit)
          .toList(),
  };
}

List<CleanupSuggestion> _suggestionsFor(List<MediaItem> media) {
  final List<MediaItem> screenshots = media
      .where((MediaItem item) => item.resolvedFolder.toLowerCase().contains('screenshot'))
      .toList();
  final List<MediaItem> large = media.toList()
    ..sort((MediaItem a, MediaItem b) => b.safeSizeBytes.compareTo(a.safeSizeBytes));
  final List<MediaItem> oldMedia = media
      .where((MediaItem item) => item.createdAt.year <= 2019)
      .toList();

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
      itemCount: large.take(50).length,
      estimatedBytes: large.take(50).fold<int>(
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

Future<void> settleSweep(WidgetTester tester) async {
  await tester.pump();
  for (int index = 0; index < 12; index++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
