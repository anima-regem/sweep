import 'dart:math';

import 'package:flutter/material.dart';

enum MediaKind { image, video, livePhoto, burst }

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
        return Icons.photo_library_outlined;
      case DiscoveryMode.largestFiles:
        return Icons.sd_storage_outlined;
      case DiscoveryMode.oldestMedia:
        return Icons.history_toggle_off;
      case DiscoveryMode.random:
        return Icons.casino_outlined;
      case DiscoveryMode.duplicates:
        return Icons.copy_all_outlined;
      case DiscoveryMode.screenshots:
        return Icons.screenshot_monitor_outlined;
      case DiscoveryMode.whatsapp:
        return Icons.chat_bubble_outline;
      case DiscoveryMode.cameraRoll:
        return Icons.camera_alt_outlined;
      case DiscoveryMode.downloads:
        return Icons.download_outlined;
      case DiscoveryMode.specificFolder:
        return Icons.folder_outlined;
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
        return Icons.image_outlined;
      case MediaKind.video:
        return Icons.play_circle_outline;
      case MediaKind.livePhoto:
        return Icons.motion_photos_on_outlined;
      case MediaKind.burst:
        return Icons.burst_mode_outlined;
    }
  }
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.kind,
    required this.createdAt,
    required this.folder,
    required this.isDuplicate,
    required this.assetId,
    this.durationSeconds,
    this.tags = const <String>[],
    this.movedToFolder,
  });

  final String id;
  final String path;
  final int sizeBytes;
  final int width;
  final int height;
  final MediaKind kind;
  final DateTime createdAt;
  final String folder;
  final int? durationSeconds;
  final bool isDuplicate;
  final List<String> tags;
  final String? movedToFolder;
  final String? assetId;

  String get resolvedFolder => movedToFolder ?? folder;

  bool get isVideo => kind == MediaKind.video;

  MediaItem copyWith({
    String? id,
    String? path,
    int? sizeBytes,
    int? width,
    int? height,
    MediaKind? kind,
    DateTime? createdAt,
    String? folder,
    int? durationSeconds,
    bool? isDuplicate,
    List<String>? tags,
    String? movedToFolder,
    String? assetId,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      folder: folder ?? this.folder,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      tags: tags ?? this.tags,
      movedToFolder: movedToFolder ?? this.movedToFolder,
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
      'isDuplicate': isDuplicate,
      'tags': tags,
      'movedToFolder': movedToFolder,
      'assetId': assetId,
    };
  }

  factory MediaItem.fromJson(Map<dynamic, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      path: json['path'] as String,
      sizeBytes: json['sizeBytes'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      kind: MediaKind.values.byName(json['kind'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      folder: json['folder'] as String,
      durationSeconds: json['durationSeconds'] as int?,
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value as String)
          .toList(),
      movedToFolder: json['movedToFolder'] as String?,
      assetId: json['assetId'] as String?,
    );
  }
}

class FolderUsage {
  const FolderUsage({
    required this.folder,
    required this.itemCount,
    required this.totalSizeBytes,
  });

  final String folder;
  final int itemCount;
  final int totalSizeBytes;
}

class StorageInsights {
  const StorageInsights({
    required this.totalMediaCount,
    required this.totalSizeBytes,
    required this.duplicateCount,
    required this.potentialFreedBytes,
    required this.largestVideos,
    required this.folderUsage,
  });

  final int totalMediaCount;
  final int totalSizeBytes;
  final int duplicateCount;
  final int potentialFreedBytes;
  final List<MediaItem> largestVideos;
  final List<FolderUsage> folderUsage;
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
