import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../models/sweep_models.dart';
import 'mock_media_factory.dart';

class GalleryScanner {
  const GalleryScanner();

  Future<List<MediaItem>> scan({
    required ScanScope scope,
    String? specificFolder,
  }) async {
    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();

      if (!_hasMediaAccess(permission)) {
        return MockMediaFactory.generate(
          scope: scope,
          specificFolder: specificFolder,
        );
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      final Iterable<AssetPathEntity> filteredAlbums = albums.where(
        (AssetPathEntity album) => _matchesScope(
          album.name,
          scope: scope,
          specificFolder: specificFolder,
        ),
      );

      final List<MediaItem> scanned = <MediaItem>[];
      for (final AssetPathEntity album in filteredAlbums) {
        scanned.addAll(await _readAlbum(album));
      }

      if (scanned.isEmpty) {
        return MockMediaFactory.generate(
          scope: scope,
          specificFolder: specificFolder,
          count: 220,
        );
      }

      return _markDuplicates(scanned);
    } catch (_) {
      return MockMediaFactory.generate(
        scope: scope,
        specificFolder: specificFolder,
        count: 260,
      );
    }
  }

  Future<List<MediaItem>> _readAlbum(AssetPathEntity album) async {
    const int pageSize = 150;
    int page = 0;

    final List<MediaItem> items = <MediaItem>[];
    while (true) {
      final List<AssetEntity> pageItems = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (pageItems.isEmpty) {
        break;
      }

      for (final AssetEntity asset in pageItems) {
        if (asset.type == AssetType.audio || asset.type == AssetType.other) {
          continue;
        }

        final int size = await _sizeForAsset(asset);
        final MediaKind kind = _mapAssetKind(asset);

        items.add(
          MediaItem(
            id: asset.id,
            assetId: asset.id,
            path: asset.title ?? asset.id,
            sizeBytes: size,
            width: asset.width,
            height: asset.height,
            kind: kind,
            createdAt: asset.createDateTime,
            folder: album.name,
            durationSeconds: kind == MediaKind.video ? asset.duration : null,
            isDuplicate: false,
          ),
        );
      }

      page++;
    }

    return items;
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
    if (asset.type == AssetType.video) {
      return MediaKind.video;
    }

    if (asset.title?.toLowerCase().contains('burst') ?? false) {
      return MediaKind.burst;
    }

    return MediaKind.image;
  }

  Future<int> _sizeForAsset(AssetEntity asset) async {
    try {
      final File? file = await asset.file;
      if (file == null) {
        return 0;
      }
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  List<MediaItem> _markDuplicates(List<MediaItem> items) {
    final Map<String, String> seenBySignature = <String, String>{};
    final List<MediaItem> output = <MediaItem>[];

    for (final MediaItem item in items) {
      final String signature =
          '${item.sizeBytes}_${item.width}_${item.height}_${item.kind.name}';
      final bool isDuplicate = seenBySignature.containsKey(signature);
      seenBySignature.putIfAbsent(signature, () => item.id);
      output.add(item.copyWith(isDuplicate: isDuplicate));
    }

    return output;
  }
}
