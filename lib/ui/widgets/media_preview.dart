import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/thumbnail_service.dart';
import '../../models/sweep_models.dart';
import '../../utils/formatters.dart';

class MediaPreview extends ConsumerWidget {
  const MediaPreview({
    required this.item,
    this.borderRadius,
    this.showMetadata = true,
    this.thumbnailSize = 720,
    super.key,
  });

  final MediaItem item;
  final BorderRadius? borderRadius;
  final bool showMetadata;
  final int thumbnailSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget content = item.assetId == null
        ? _PlaceholderContent(item: item)
        : FutureBuilder<Uint8List?>(
            future: ref.read(thumbnailServiceProvider).load(
              item.assetId!,
              size: thumbnailSize,
            ),
            builder:
                (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return _PlaceholderContent(item: item);
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                      if (item.kind == MediaKind.video)
                        const Align(
                          alignment: Alignment.center,
                          child: _VideoPlayBadge(),
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
    final SweepThemeData theme = SweepTheme.of(context);

    return Align(
      alignment: Alignment.bottomLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              const Color(0xDE03060E),
              const Color(0xA00A1020),
              const Color(0x00000000),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(theme.radii.md),
            bottomRight: Radius.circular(theme.radii.md),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: <Widget>[
              Icon(item.kind.icon, color: theme.colors.textOnAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.kind.label} • ${formatMaybeBytes(item.sizeBytes)} • ${item.resolvedFolder}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.detail.copyWith(
                    color: theme.colors.textOnAccent.withValues(alpha: 0.88),
                  ),
                ),
              ),
              if (item.kind == MediaKind.video)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xA2000000),
                    borderRadius: BorderRadius.circular(theme.radii.pill),
                  ),
                  child: Text(
                    formatDurationSeconds(item.durationSeconds),
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.textOnAccent,
                    ),
                  ),
                ),
            ],
          ),
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
    final SweepThemeData theme = SweepTheme.of(context);
    final int seed = item.id.codeUnitAt(item.id.length - 1);
    final Color first = HSLColor.fromAHSL(
      1,
      (seed * 31) % 360,
      0.74,
      0.52,
    ).toColor();
    final Color second = HSLColor.fromAHSL(
      1,
      (seed * 53 + 90) % 360,
      0.62,
      0.28,
    ).toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[first, second],
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth < 100 || constraints.maxHeight < 100;

          return Stack(
            children: <Widget>[
              Positioned(
                top: compact ? -12 : -36,
                right: compact ? -8 : -26,
                child: Icon(
                  item.kind.icon,
                  size: compact ? 82 : 170,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.14),
                ),
              ),
              Center(
                child: compact
                    ? Icon(
                        item.kind.icon,
                        size: 28,
                        color: const Color(0xFFFFFFFF),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            item.kind.icon,
                            size: 54,
                            color: const Color(0xFFFFFFFF),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.kind.label,
                            style: theme.typography.title.copyWith(
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              item.sizeBytes == null
                                  ? 'Progressive metadata'
                                  : 'Instant preview',
                              style: theme.typography.detail.copyWith(
                                color: const Color(
                                  0xFFFFFFFF,
                                ).withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (!compact)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    formatDate(item.createdAt),
                    style: theme.typography.detail.copyWith(
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.94),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoPlayBadge extends StatelessWidget {
  const _VideoPlayBadge();

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xAA000000),
        border: Border.all(color: theme.colors.textOnAccent.withValues(alpha: 0.16)),
      ),
      child: Icon(
        CupertinoIcons.play_fill,
        size: 24,
        color: theme.colors.textOnAccent,
      ),
    );
  }
}
