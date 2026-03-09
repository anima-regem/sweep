import 'dart:math';

import 'package:flutter/cupertino.dart';

enum MediaKind { image, video, livePhoto, burst }

enum DuplicateStatus { unresolved, unique, duplicate }

enum SwipeDecision { keep, delete, tag, skip }

enum SwipeDirection { left, right, up, down }

enum DiscoveryMode {
  all,
  largestFiles,
  oldestMedia,
  random,
  duplicates,
  screenshots,
  whatsapp,
  cameraRoll,
  downloads,
  specificFolder,
}

enum ScanScope {
  entireGallery,
  specificFolder,
  cameraRollOnly,
  whatsappMedia,
  screenshots,
  downloads,
}

extension ScanScopeLabel on ScanScope {
  String get label {
    switch (this) {
      case ScanScope.entireGallery:
        return 'Entire Gallery';
      case ScanScope.specificFolder:
        return 'Specific Folder';
      case ScanScope.cameraRollOnly:
        return 'Camera Roll Only';
      case ScanScope.whatsappMedia:
        return 'WhatsApp Media';
      case ScanScope.screenshots:
        return 'Screenshots';
      case ScanScope.downloads:
        return 'Downloads';
    }
  }
}

extension DiscoveryModeX on DiscoveryMode {
  String get label {
    switch (this) {
      case DiscoveryMode.all:
        return 'Entire Gallery';
      case DiscoveryMode.largestFiles:
        return 'Largest Files';
      case DiscoveryMode.oldestMedia:
        return 'Oldest Media';
      case DiscoveryMode.random:
        return 'Random Mode';
      case DiscoveryMode.duplicates:
        return 'Duplicate Detector';
      case DiscoveryMode.screenshots:
        return 'Screenshots Mode';
      case DiscoveryMode.whatsapp:
        return 'WhatsApp Media';
      case DiscoveryMode.cameraRoll:
        return 'Camera Roll';
      case DiscoveryMode.downloads:
        return 'Downloads';
      case DiscoveryMode.specificFolder:
        return 'Folder Swipe';
    }
  }

  IconData get icon {
    switch (this) {
      case DiscoveryMode.all:
        return CupertinoIcons.rectangle_stack;
      case DiscoveryMode.largestFiles:
        return CupertinoIcons.archivebox;
      case DiscoveryMode.oldestMedia:
        return CupertinoIcons.clock;
      case DiscoveryMode.random:
        return CupertinoIcons.shuffle;
      case DiscoveryMode.duplicates:
        return CupertinoIcons.square_on_square;
      case DiscoveryMode.screenshots:
        return CupertinoIcons.device_phone_portrait;
      case DiscoveryMode.whatsapp:
        return CupertinoIcons.chat_bubble_2;
      case DiscoveryMode.cameraRoll:
        return CupertinoIcons.camera;
      case DiscoveryMode.downloads:
        return CupertinoIcons.arrow_down_circle;
      case DiscoveryMode.specificFolder:
        return CupertinoIcons.folder;
    }
  }
}

extension MediaKindX on MediaKind {
  String get label {
    switch (this) {
      case MediaKind.image:
        return 'Image';
      case MediaKind.video:
        return 'Video';
      case MediaKind.livePhoto:
        return 'Live Photo';
      case MediaKind.burst:
        return 'Burst';
    }
  }

  IconData get icon {
    switch (this) {
      case MediaKind.image:
        return CupertinoIcons.photo;
      case MediaKind.video:
        return CupertinoIcons.play_circle;
      case MediaKind.livePhoto:
        return CupertinoIcons.sparkles;
      case MediaKind.burst:
        return CupertinoIcons.square_grid_2x2;
    }
  }
}

class MediaOverlay {
  const MediaOverlay({this.tags = const <String>[], this.movedToFolder});

  final List<String> tags;
  final String? movedToFolder;

  bool get isEmpty => tags.isEmpty && movedToFolder == null;

  MediaOverlay copyWith({
    List<String>? tags,
    String? movedToFolder,
    bool clearMovedToFolder = false,
  }) {
    return MediaOverlay(
      tags: tags ?? this.tags,
      movedToFolder: clearMovedToFolder
          ? null
          : (movedToFolder ?? this.movedToFolder),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'tags': tags, 'movedToFolder': movedToFolder};
  }

  factory MediaOverlay.fromJson(Map<dynamic, dynamic> json) {
    return MediaOverlay(
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value as String)
          .toList(),
      movedToFolder: json['movedToFolder'] as String?,
    );
  }
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.path,
    required this.width,
    required this.height,
    required this.kind,
    required this.createdAt,
    required this.folder,
    required this.assetId,
    this.sizeBytes,
    this.durationSeconds,
    this.duplicateStatus = DuplicateStatus.unresolved,
    this.tags = const <String>[],
    this.movedToFolder,
  });

  final String id;
  final String path;
  final int? sizeBytes;
  final int width;
  final int height;
  final MediaKind kind;
  final DateTime createdAt;
  final String folder;
  final int? durationSeconds;
  final DuplicateStatus duplicateStatus;
  final List<String> tags;
  final String? movedToFolder;
  final String? assetId;

  String get resolvedFolder => movedToFolder ?? folder;

  bool get isVideo => kind == MediaKind.video;

  bool get isDuplicate => duplicateStatus == DuplicateStatus.duplicate;

  bool get hasResolvedSize => sizeBytes != null;

  int get safeSizeBytes => sizeBytes ?? 0;

  String get displayName {
    final int separator = path.lastIndexOf('/');
    if (separator == -1 || separator == path.length - 1) {
      return path;
    }
    return path.substring(separator + 1);
  }

  MediaItem copyWith({
    String? id,
    String? path,
    int? sizeBytes,
    bool clearSize = false,
    int? width,
    int? height,
    MediaKind? kind,
    DateTime? createdAt,
    String? folder,
    int? durationSeconds,
    DuplicateStatus? duplicateStatus,
    List<String>? tags,
    String? movedToFolder,
    bool clearMovedToFolder = false,
    String? assetId,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: clearSize ? null : (sizeBytes ?? this.sizeBytes),
      width: width ?? this.width,
      height: height ?? this.height,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      folder: folder ?? this.folder,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      tags: tags ?? this.tags,
      movedToFolder: clearMovedToFolder
          ? null
          : (movedToFolder ?? this.movedToFolder),
      assetId: assetId ?? this.assetId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'sizeBytes': sizeBytes,
      'width': width,
      'height': height,
      'kind': kind.name,
      'createdAt': createdAt.toIso8601String(),
      'folder': folder,
      'durationSeconds': durationSeconds,
      'duplicateStatus': duplicateStatus.name,
      'tags': tags,
      'movedToFolder': movedToFolder,
      'assetId': assetId,
    };
  }

  factory MediaItem.fromJson(Map<dynamic, dynamic> json) {
    final String? duplicateStatus = json['duplicateStatus'] as String?;
    final bool legacyDuplicate = json['isDuplicate'] as bool? ?? false;

    return MediaItem(
      id: json['id'] as String,
      path: json['path'] as String,
      sizeBytes: json['sizeBytes'] as int?,
      width: json['width'] as int,
      height: json['height'] as int,
      kind: MediaKind.values.byName(json['kind'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      folder: json['folder'] as String,
      durationSeconds: json['durationSeconds'] as int?,
      duplicateStatus: duplicateStatus == null
          ? (legacyDuplicate
                ? DuplicateStatus.duplicate
                : DuplicateStatus.unique)
          : DuplicateStatus.values.byName(duplicateStatus),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value as String)
          .toList(),
      movedToFolder: json['movedToFolder'] as String?,
      assetId: json['assetId'] as String?,
    );
  }
}

class GalleryPage {
  const GalleryPage({
    this.items = const <MediaItem>[],
    this.offset = 0,
    this.hasMore = false,
    this.totalCount = 0,
  });

  final List<MediaItem> items;
  final int offset;
  final bool hasMore;
  final int totalCount;

  GalleryPage copyWith({
    List<MediaItem>? items,
    int? offset,
    bool? hasMore,
    int? totalCount,
  }) {
    return GalleryPage(
      items: items ?? this.items,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ScanProgress {
  const ScanProgress({
    required this.isRunning,
    required this.indexedCount,
    required this.enrichedCount,
    required this.label,
    this.totalAlbums,
  });

  const ScanProgress.idle()
    : isRunning = false,
      indexedCount = 0,
      enrichedCount = 0,
      label = 'Gallery ready',
      totalAlbums = null;

  final bool isRunning;
  final int indexedCount;
  final int enrichedCount;
  final String label;
  final int? totalAlbums;

  ScanProgress copyWith({
    bool? isRunning,
    int? indexedCount,
    int? enrichedCount,
    String? label,
    int? totalAlbums,
  }) {
    return ScanProgress(
      isRunning: isRunning ?? this.isRunning,
      indexedCount: indexedCount ?? this.indexedCount,
      enrichedCount: enrichedCount ?? this.enrichedCount,
      label: label ?? this.label,
      totalAlbums: totalAlbums ?? this.totalAlbums,
    );
  }
}

class FolderUsage {
  const FolderUsage({
    required this.folder,
    required this.itemCount,
    required this.totalSizeBytes,
    this.unresolvedSizeCount = 0,
  });

  final String folder;
  final int itemCount;
  final int totalSizeBytes;
  final int unresolvedSizeCount;
}

class GallerySummary {
  const GallerySummary({
    required this.totalMediaCount,
    required this.totalSizeBytes,
    required this.duplicateCount,
    required this.potentialFreedBytes,
    required this.largestVideos,
    required this.folderUsage,
    required this.unresolvedSizeCount,
    required this.isPartial,
  });

  const GallerySummary.empty()
    : totalMediaCount = 0,
      totalSizeBytes = 0,
      duplicateCount = 0,
      potentialFreedBytes = 0,
      largestVideos = const <MediaItem>[],
      folderUsage = const <FolderUsage>[],
      unresolvedSizeCount = 0,
      isPartial = true;

  final int totalMediaCount;
  final int totalSizeBytes;
  final int duplicateCount;
  final int potentialFreedBytes;
  final List<MediaItem> largestVideos;
  final List<FolderUsage> folderUsage;
  final int unresolvedSizeCount;
  final bool isPartial;
}

class CleanupSuggestion {
  const CleanupSuggestion({
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.itemCount,
    required this.estimatedBytes,
  });

  final String title;
  final String subtitle;
  final DiscoveryMode mode;
  final int itemCount;
  final int estimatedBytes;
}

List<T> shuffled<T>(List<T> input, Random random) {
  final List<T> mutable = List<T>.from(input);
  mutable.shuffle(random);
  return mutable;
}
