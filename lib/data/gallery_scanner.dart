import 'package:photo_manager/photo_manager.dart';

import '../models/sweep_models.dart';
import 'mock_media_factory.dart';

class GalleryScanBatch {
  const GalleryScanBatch({
    required this.items,
    required this.indexedCount,
    required this.albumCount,
    required this.label,
    this.complete = false,
  });

  final List<MediaItem> items;
  final int indexedCount;
  final int albumCount;
  final String label;
  final bool complete;
}

class GalleryScanner {
  const GalleryScanner();

  static const List<String> _videoExtensions = <String>[
    '.mp4',
    '.mov',
    '.mkv',
    '.avi',
    '.m4v',
    '.3gp',
    '.webm',
  ];

  static const List<String> _imageExtensions = <String>[
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
    '.heif',
  ];

  Stream<GalleryScanBatch> scanBatches({
    required ScanScope scope,
    String? specificFolder,
    int batchSize = 120,
  }) async* {
    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();

      if (!_hasMediaAccess(permission)) {
        yield* _mockBatches(
          scope: scope,
          specificFolder: specificFolder,
          batchSize: batchSize,
        );
        return;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
        hasAll: true,
      );

      final List<AssetPathEntity> filteredAlbums = albums.where((
        AssetPathEntity album,
      ) {
        return _matchesScope(
          album.name,
          scope: scope,
          specificFolder: specificFolder,
        );
      }).toList();

      int indexedCount = 0;

      for (final AssetPathEntity album in filteredAlbums) {
        int page = 0;

        while (true) {
          final List<AssetEntity> pageItems = await album.getAssetListPaged(
            page: page,
            size: batchSize,
          );

          if (pageItems.isEmpty) {
            break;
          }

          final List<MediaItem> items = pageItems
              .where(_isSupportedAsset)
              .map((AssetEntity asset) => _assetToMedia(asset, album.name))
              .toList();

          indexedCount += items.length;

          if (items.isNotEmpty) {
            yield GalleryScanBatch(
              items: items,
              indexedCount: indexedCount,
              albumCount: filteredAlbums.length,
              label: 'Indexing ${album.name}',
            );
          }

          page++;
        }
      }

      yield GalleryScanBatch(
        items: const <MediaItem>[],
        indexedCount: indexedCount,
        albumCount: filteredAlbums.length,
        label: 'Index ready',
        complete: true,
      );
    } catch (_) {
      yield* _mockBatches(
        scope: scope,
        specificFolder: specificFolder,
        batchSize: batchSize,
      );
    }
  }

  MediaItem _assetToMedia(AssetEntity asset, String albumName) {
    final MediaKind kind = _mapAssetKind(asset);
    return MediaItem(
      id: asset.id,
      assetId: asset.id,
      path: asset.title ?? asset.id,
      sizeBytes: null,
      width: asset.width,
      height: asset.height,
      kind: kind,
      createdAt: asset.createDateTime,
      folder: albumName,
      durationSeconds: kind == MediaKind.video ? asset.duration : null,
      duplicateStatus: DuplicateStatus.unresolved,
    );
  }

  Stream<GalleryScanBatch> _mockBatches({
    required ScanScope scope,
    required String? specificFolder,
    required int batchSize,
  }) async* {
    final List<MediaItem> generated = MockMediaFactory.generate(
      scope: scope,
      specificFolder: specificFolder,
      count: 260,
    );

    int indexedCount = 0;
    for (int start = 0; start < generated.length; start += batchSize) {
      final int end = start + batchSize > generated.length
          ? generated.length
          : start + batchSize;
      final List<MediaItem> batch = generated.sublist(start, end);
      indexedCount += batch.length;
      yield GalleryScanBatch(
        items: batch,
        indexedCount: indexedCount,
        albumCount: 1,
        label: 'Indexing demo gallery',
      );
    }

    yield GalleryScanBatch(
      items: const <MediaItem>[],
      indexedCount: indexedCount,
      albumCount: 1,
      label: 'Demo index ready',
      complete: true,
    );
  }

  bool _hasMediaAccess(PermissionState permission) {
    return permission.isAuth || permission == PermissionState.limited;
  }

  bool _matchesScope(
    String albumName, {
    required ScanScope scope,
    required String? specificFolder,
  }) {
    final String normalized = albumName.toLowerCase();

    switch (scope) {
      case ScanScope.entireGallery:
        return true;
      case ScanScope.specificFolder:
        if (specificFolder == null || specificFolder.trim().isEmpty) {
          return true;
        }
        return normalized == specificFolder.toLowerCase();
      case ScanScope.cameraRollOnly:
        return normalized.contains('camera') || normalized.contains('dcim');
      case ScanScope.whatsappMedia:
        return normalized.contains('whatsapp');
      case ScanScope.screenshots:
        return normalized.contains('screenshot');
      case ScanScope.downloads:
        return normalized.contains('download');
    }
  }

  MediaKind _mapAssetKind(AssetEntity asset) {
    if (_isVideoLikeAsset(asset)) {
      return MediaKind.video;
    }

    if (asset.title?.toLowerCase().contains('burst') ?? false) {
      return MediaKind.burst;
    }

    return MediaKind.image;
  }

  bool _isSupportedAsset(AssetEntity asset) {
    if (asset.type == AssetType.image || asset.type == AssetType.video) {
      return true;
    }

    if (asset.type == AssetType.audio) {
      return false;
    }

    return _isVideoLikeAsset(asset) || _isImageLikeAsset(asset);
  }

  bool _isVideoLikeAsset(AssetEntity asset) {
    if (asset.type == AssetType.video) {
      return true;
    }
    final String title = asset.title?.toLowerCase() ?? '';
    return _videoExtensions.any(title.endsWith);
  }

  bool _isImageLikeAsset(AssetEntity asset) {
    if (asset.type == AssetType.image) {
      return true;
    }
    final String title = asset.title?.toLowerCase() ?? '';
    return _imageExtensions.any(title.endsWith);
  }
}
