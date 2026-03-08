import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../widgets/media_tile.dart';

class TrashTab extends ConsumerStatefulWidget {
  const TrashTab({super.key});

  @override
  ConsumerState<TrashTab> createState() => _TrashTabState();
}

class _TrashTabState extends ConsumerState<TrashTab> {
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final List<MediaItem> trash = controller.trashItems();

    if (_selected.any(
      (String id) => !trash.any((MediaItem item) => item.id == id),
    )) {
      _selected.removeWhere(
        (String id) => !trash.any((MediaItem item) => item.id == id),
      );
    }

    final int totalBytes = trash.fold<int>(
      0,
      (int sum, MediaItem item) => sum + item.sizeBytes,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Deletion Review System',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are about to delete ${trash.length} files '
                  '(${formatBytes(totalBytes)}).',
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () {
                                controller.restoreItems(_selected);
                                setState(_selected.clear);
                              },
                        icon: const Icon(Icons.restore_outlined),
                        label: const Text('Restore Selected'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF25F5C),
                        ),
                        onPressed: _selected.isEmpty
                            ? null
                            : () => _confirmDelete(
                                context,
                                count: _selected.length,
                                onConfirm: () {
                                  controller.permanentlyDeleteItems(_selected);
                                  setState(_selected.clear);
                                },
                              ),
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Delete Selected'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: trash.isEmpty
                        ? null
                        : () => _confirmDelete(
                            context,
                            count: trash.length,
                            onConfirm: () {
                              controller.permanentlyDeleteItems(
                                trash.map((MediaItem item) => item.id).toSet(),
                              );
                              setState(_selected.clear);
                            },
                          ),
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: const Text('Delete All'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (trash.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Trash is empty. Swipe left in Swipe Mode to queue media.',
              ),
            ),
          )
        else
          ...trash.map(
            (MediaItem item) => MediaTile(
              item: item,
              selected: _selected.contains(item.id),
              onToggle: () {
                setState(() {
                  if (_selected.contains(item.id)) {
                    _selected.remove(item.id);
                  } else {
                    _selected.add(item.id);
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required int count,
    required VoidCallback onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permanent Delete'),
          content: Text(
            'This will permanently remove $count files from Sweep index. Continue?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF25F5C),
              ),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
