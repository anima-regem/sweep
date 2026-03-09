import 'dart:math';

import '../models/sweep_models.dart';

class MockMediaFactory {
  const MockMediaFactory();

  static final List<String> _folders = <String>[
    'Camera',
    'Screenshots',
    'WhatsApp Images',
    'WhatsApp Video',
    'Downloads',
    'Travel',
    'Family',
    'Work',
    'Memes',
  ];

  static List<MediaItem> generate({
    required ScanScope scope,
    String? specificFolder,
    int count = 640,
  }) {
    final Random random = Random(37);
    final List<MediaItem> items = <MediaItem>[];

    for (int i = 0; i < count; i++) {
      final String folder = _folders[random.nextInt(_folders.length)];
      final bool isVideo = random.nextInt(100) < 28;
      final int width = isVideo ? 1920 : (720 + random.nextInt(1801));
      final int height = isVideo ? 1080 : (720 + random.nextInt(1801));
      final int baseSize = isVideo
          ? 2 * 1024 * 1024 + random.nextInt(90 * 1024 * 1024)
          : 250 * 1024 + random.nextInt(12 * 1024 * 1024);
      final int duplicateOffset = i % 27 == 0 ? -1 : i;
      final int sizeBytes = duplicateOffset == -1 ? 4 * 1024 * 1024 : baseSize;

      final MediaKind kind;
      if (isVideo) {
        kind = MediaKind.video;
      } else {
        final int marker = random.nextInt(100);
        if (marker < 5) {
          kind = MediaKind.livePhoto;
        } else if (marker < 8) {
          kind = MediaKind.burst;
        } else {
          kind = MediaKind.image;
        }
      }

      items.add(
        MediaItem(
          id: 'mock_$i',
          assetId: null,
          path: '/mock/$folder/item_$i',
          sizeBytes: sizeBytes,
          width: width,
          height: height,
          kind: kind,
          createdAt: DateTime.now().subtract(
            Duration(days: random.nextInt(2900)),
          ),
          folder: folder,
          durationSeconds: isVideo ? 10 + random.nextInt(320) : null,
          duplicateStatus: DuplicateStatus.unique,
        ),
      );
    }

    final List<MediaItem> marked = _markDuplicates(items);
    final List<MediaItem> filtered = marked.where((MediaItem item) {
      return _matchesScope(item, scope: scope, specificFolder: specificFolder);
    }).toList();

    return filtered;
  }

  static bool _matchesScope(
    MediaItem item, {
    required ScanScope scope,
    required String? specificFolder,
  }) {
    final String normalized = item.folder.toLowerCase();

    switch (scope) {
      case ScanScope.entireGallery:
        return true;
      case ScanScope.specificFolder:
        if (specificFolder == null || specificFolder.trim().isEmpty) {
          return true;
        }
        return normalized == specificFolder.toLowerCase();
      case ScanScope.cameraRollOnly:
        return normalized.contains('camera');
      case ScanScope.whatsappMedia:
        return normalized.contains('whatsapp');
      case ScanScope.screenshots:
        return normalized.contains('screenshot');
      case ScanScope.downloads:
        return normalized.contains('download');
    }
  }

  static List<MediaItem> _markDuplicates(List<MediaItem> items) {
    final Map<String, String> signatureToPrimary = <String, String>{};
    final List<MediaItem> output = <MediaItem>[];

    for (final MediaItem item in items) {
      final String signature =
          '${item.sizeBytes}_${item.width}_${item.height}_${item.kind.name}';
      final bool isDuplicate = signatureToPrimary.containsKey(signature);
      signatureToPrimary.putIfAbsent(signature, () => item.id);

      output.add(
        item.copyWith(
          duplicateStatus: isDuplicate
              ? DuplicateStatus.duplicate
              : DuplicateStatus.unique,
        ),
      );
    }

    return output;
  }
}
