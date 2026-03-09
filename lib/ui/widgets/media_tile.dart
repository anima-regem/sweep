import 'package:flutter/cupertino.dart';

import '../../models/sweep_models.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';
import 'media_preview.dart';

class MediaTile extends StatelessWidget {
  const MediaTile({
    required this.item,
    required this.selected,
    required this.onToggle,
    this.trailing,
    super.key,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SweepListRow(
      onTap: onToggle,
      leading: SizedBox(
        width: 58,
        height: 58,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MediaPreview(
            item: item,
            showMetadata: false,
            thumbnailSize: 160,
          ),
        ),
      ),
      title: '${item.kind.label} • ${formatMaybeBytes(item.sizeBytes)}',
      subtitle: '${item.resolvedFolder} • ${formatDate(item.createdAt)}',
      trailing: trailing ?? SweepCheckIndicator(selected: selected),
    );
  }
}
