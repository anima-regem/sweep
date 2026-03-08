import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/sweep_models.dart';
import '../../utils/formatters.dart';

class MediaPreview extends StatelessWidget {
  const MediaPreview({
    required this.item,
    this.borderRadius,
    this.showMetadata = true,
    super.key,
  });

  final MediaItem item;
  final BorderRadius? borderRadius;
  final bool showMetadata;

  @override
  Widget build(BuildContext context) {
    final Widget content = item.assetId == null
        ? _PlaceholderContent(item: item)
        : FutureBuilder<AssetEntity?>(
            future: AssetEntity.fromId(item.assetId!),
            builder:
                (BuildContext context, AsyncSnapshot<AssetEntity?> snapshot) {
                  final AssetEntity? asset = snapshot.data;
                  if (asset == null) {
                    return _PlaceholderContent(item: item);
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      FutureBuilder<Uint8List?>(
                        future: asset.thumbnailDataWithSize(
                          const ThumbnailSize.square(1400),
                        ),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<Uint8List?> thumbnailSnapshot,
                            ) {
                              if (!thumbnailSnapshot.hasData ||
                                  thumbnailSnapshot.data == null) {
                                return _PlaceholderContent(item: item);
                              }

                              return Image.memory(
                                thumbnailSnapshot.data!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              );
                            },
                      ),
                      if (item.kind == MediaKind.video)
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: 72,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  );
                },
          );

    final Widget wrapped = borderRadius == null
        ? content
        : ClipRRect(borderRadius: borderRadius!, child: content);

    if (!showMetadata) {
      return wrapped;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        wrapped,
        _MetadataOverlay(item: item),
      ],
    );
  }
}

class _MetadataOverlay extends StatelessWidget {
  const _MetadataOverlay({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.75),
              Colors.transparent,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          children: <Widget>[
            Icon(item.kind.icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.kind.label} • ${formatBytes(item.sizeBytes)} • ${item.resolvedFolder}',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.kind == MediaKind.video)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  formatDurationSeconds(item.durationSeconds),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final int seed = item.id.codeUnitAt(item.id.length - 1);
    final Color first = HSLColor.fromAHSL(
      1,
      (seed * 31) % 360,
      0.65,
      0.45,
    ).toColor();
    final Color second = HSLColor.fromAHSL(
      1,
      (seed * 53 + 90) % 360,
      0.6,
      0.34,
    ).toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[first, second],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -30,
            child: Icon(
              item.kind.icon,
              size: 180,
              color: Colors.white.withValues(alpha: 0.17),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.kind.icon, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  item.kind.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (item.kind == MediaKind.video)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Muted auto-preview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(
              formatDate(item.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
