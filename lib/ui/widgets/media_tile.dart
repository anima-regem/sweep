import 'package:flutter/material.dart';

import '../../models/sweep_models.dart';
import '../../utils/formatters.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onToggle,
        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MediaPreview(item: item, showMetadata: false),
          ),
        ),
        title: Text(
          '${item.kind.label} • ${formatBytes(item.sizeBytes)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.resolvedFolder} • ${formatDate(item.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            trailing ?? Checkbox(value: selected, onChanged: (_) => onToggle()),
      ),
    );
  }
}
