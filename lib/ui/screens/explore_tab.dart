import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../widgets/media_preview.dart';

class ExploreTab extends ConsumerWidget {
  const ExploreTab({required this.onApplyMode, super.key});

  final void Function(DiscoveryMode mode, {String? folder}) onApplyMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final List<String> folders = controller.folders();
    final List<MediaItem> items = controller.mediaForActiveMode(
      includeProcessed: true,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Smart Discovery Modes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DiscoveryMode.values
                      .map(
                        (DiscoveryMode mode) => ChoiceChip(
                          label: Text(mode.label),
                          selected: state.discoveryMode == mode,
                          onSelected: (_) {
                            if (mode == DiscoveryMode.specificFolder &&
                                state.specificFolder == null &&
                                folders.isNotEmpty) {
                              onApplyMode(mode, folder: folders.first);
                              return;
                            }

                            onApplyMode(mode);
                          },
                        ),
                      )
                      .toList(),
                ),
                if (state.discoveryMode ==
                    DiscoveryMode.specificFolder) ...<Widget>[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue:
                        state.specificFolder ??
                        (folders.isEmpty ? null : folders.first),
                    decoration: const InputDecoration(
                      labelText: 'Folder Swipe',
                      border: OutlineInputBorder(),
                    ),
                    items: folders
                        .map(
                          (String folder) => DropdownMenuItem<String>(
                            value: folder,
                            child: Text(folder),
                          ),
                        )
                        .toList(),
                    onChanged: folders.isEmpty
                        ? null
                        : (String? folder) {
                            if (folder == null) {
                              return;
                            }
                            onApplyMode(
                              DiscoveryMode.specificFolder,
                              folder: folder,
                            );
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Bulk Selection Mode',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.clearBulkSelection,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : controller.markSelectedForDeletion,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : () => _showTagDialog(context, controller),
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Tag'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : () => _showMoveDialog(context, controller),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: const Text('Move'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${state.selectedBulkIds.length} selected • ${items.length} items in ${state.discoveryMode.label}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 26),
            child: Center(child: Text('No items in this mode.')),
          )
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (BuildContext context, int index) {
              final MediaItem item = items[index];
              final bool selected = state.selectedBulkIds.contains(item.id);

              return GestureDetector(
                onTap: () => controller.toggleBulkSelection(item.id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1F8A8A)
                          : Colors.black12,
                      width: selected ? 2 : 1,
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                                child: MediaPreview(
                                  item: item,
                                  showMetadata: false,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: selected
                                    ? const Color(0xFF1F8A8A)
                                    : Colors.white,
                                child: Icon(
                                  selected
                                      ? Icons.check
                                      : Icons.circle_outlined,
                                  size: 14,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.resolvedFolder,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${item.kind.label} • ${formatBytes(item.sizeBytes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showTagDialog(
    BuildContext context,
    SweepController controller,
  ) async {
    final TextEditingController textController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign Tag'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Travel / Work / Family',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String tag = textController.text.trim();
                if (tag.isNotEmpty) {
                  controller.bulkAssignTag(tag);
                  controller.addCustomTag(tag);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMoveDialog(
    BuildContext context,
    SweepController controller,
  ) async {
    final TextEditingController textController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Move to Folder'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Travel 2026'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String folder = textController.text.trim();
                if (folder.isNotEmpty) {
                  controller.bulkMoveToFolder(folder);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Move'),
            ),
          ],
        );
      },
    );
  }
}
