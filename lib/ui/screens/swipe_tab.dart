import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/swipe_deck.dart';

class SwipeTab extends ConsumerStatefulWidget {
  const SwipeTab({required this.onOpenTrash, super.key});

  final VoidCallback onOpenTrash;

  @override
  ConsumerState<SwipeTab> createState() => _SwipeTabState();
}

class _SwipeTabState extends ConsumerState<SwipeTab> {
  bool _dialogVisible = false;

  @override
  Widget build(BuildContext context) {
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );

    if (state.showCompletion && !_dialogVisible) {
      _dialogVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<void>(
          context: context,
          builder: (BuildContext context) => CompletionDialog(
            processed: state.lastSessionProcessed,
            freedBytes: state.lastSessionFreedBytes,
          ),
        );

        if (!mounted) {
          return;
        }

        controller.dismissCompletion();
        _dialogVisible = false;
      });
    }

    final List<MediaItem> queue = controller.swipeQueue();
    final MediaItem? current = queue.isNotEmpty ? queue.first : null;
    final MediaItem? next = queue.length > 1 ? queue[1] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        _buildModeSelector(state: state, controller: controller),
        const SizedBox(height: 8),
        _buildSessionSummary(queueCount: queue.length, state: state),
        const SizedBox(height: 12),
        if (current == null)
          _EmptyQueueCard(onOpenTrash: widget.onOpenTrash)
        else
          Column(
            children: <Widget>[
              SwipeDeck(
                current: current,
                next: next,
                onTap: () => _openCardActions(current),
                onSwipe: (MediaItem item, SwipeDirection direction) {
                  _handleSwipe(item, direction);
                },
              ),
              const SizedBox(height: 14),
              _InfoBanner(item: current),
              const SizedBox(height: 12),
              _ActionButtons(
                onSkip: () => _handleSwipe(current, SwipeDirection.down),
                onDelete: () => _handleSwipe(current, SwipeDirection.left),
                onTag: () => _handleSwipe(current, SwipeDirection.up),
                onKeep: () => _handleSwipe(current, SwipeDirection.right),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildModeSelector({
    required SweepState state,
    required SweepController controller,
  }) {
    final List<String> folders = controller.folders();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Smart Discovery Mode',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<DiscoveryMode>(
              initialValue: state.discoveryMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: DiscoveryMode.values
                  .map(
                    (DiscoveryMode mode) => DropdownMenuItem<DiscoveryMode>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                  )
                  .toList(),
              onChanged: (DiscoveryMode? mode) {
                if (mode == null) {
                  return;
                }

                if (mode == DiscoveryMode.specificFolder &&
                    state.specificFolder == null &&
                    folders.isNotEmpty) {
                  controller.setDiscoveryMode(mode, folderName: folders.first);
                  return;
                }

                controller.setDiscoveryMode(mode);
              },
            ),
            if (state.discoveryMode ==
                DiscoveryMode.specificFolder) ...<Widget>[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue:
                    state.specificFolder ??
                    (folders.isEmpty ? null : folders.first),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Folder',
                  isDense: true,
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
                    : (String? value) {
                        if (value == null) {
                          return;
                        }
                        controller.setDiscoveryMode(
                          DiscoveryMode.specificFolder,
                          folderName: value,
                        );
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSummary({
    required int queueCount,
    required SweepState state,
  }) {
    final int trashCount = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatPill(
            title: 'Pending',
            value: '$queueCount',
            color: const Color(0xFF3567D6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            title: 'Trash Queue',
            value: '$trashCount',
            color: const Color(0xFFF25F5C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            title: 'Sessions',
            value: '${state.sessionsCompleted}',
            color: const Color(0xFF1F8A8A),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSwipe(MediaItem item, SwipeDirection direction) async {
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );

    switch (direction) {
      case SwipeDirection.left:
        HapticFeedback.lightImpact();
        controller.registerSwipe(item, SwipeDirection.left);
        break;
      case SwipeDirection.right:
        HapticFeedback.mediumImpact();
        controller.registerSwipe(item, SwipeDirection.right);
        break;
      case SwipeDirection.up:
        HapticFeedback.selectionClick();
        final _TagMoveAction? action = await _showTagMoveSheet(item);
        if (action == null) {
          return;
        }
        controller.registerSwipe(
          item,
          SwipeDirection.up,
          tags: action.tags,
          moveToFolder: action.folder,
        );
        break;
      case SwipeDirection.down:
        HapticFeedback.selectionClick();
        controller.registerSwipe(item, SwipeDirection.down);
        break;
    }
  }

  Future<void> _openCardActions(MediaItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.path,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text('Date: ${formatDate(item.createdAt)}'),
                Text('Size: ${formatBytes(item.sizeBytes)}'),
                Text('Folder: ${item.resolvedFolder}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _handleSwipe(item, SwipeDirection.up);
                      },
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text('Tag / Move'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleSwipe(item, SwipeDirection.left);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleSwipe(item, SwipeDirection.right);
                      },
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('Keep'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_TagMoveAction?> _showTagMoveSheet(MediaItem item) async {
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final SweepState state = ref.read(sweepControllerProvider);

    final Set<String> selectedTags = Set<String>.from(item.tags);
    String? selectedFolder;
    final TextEditingController tagController = TextEditingController();

    return showModalBottomSheet<_TagMoveAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Tag & Organize',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.customTags
                                .map(
                                  (String tag) => FilterChip(
                                    label: Text(tag),
                                    selected: selectedTags.contains(tag),
                                    onSelected: (bool selected) {
                                      setModalState(() {
                                        if (selected) {
                                          selectedTags.add(tag);
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: tagController,
                                  decoration: const InputDecoration(
                                    labelText: 'Create tag',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {
                                  final String tag = tagController.text.trim();
                                  if (tag.isEmpty) {
                                    return;
                                  }
                                  controller.addCustomTag(tag);
                                  setModalState(() {
                                    selectedTags.add(tag);
                                    tagController.clear();
                                  });
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: item.resolvedFolder,
                            decoration: const InputDecoration(
                              labelText: 'Move to folder (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: controller
                                .folders()
                                .map(
                                  (String folder) => DropdownMenuItem<String>(
                                    value: folder,
                                    child: Text(folder),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? value) {
                              setModalState(() {
                                selectedFolder = value;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                  _TagMoveAction(
                                    tags: selectedTags.toList(),
                                    folder: selectedFolder,
                                  ),
                                );
                              },
                              child: const Text('Apply Tag / Move'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: <Widget>[
          _Chip(
            text: formatDate(item.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
          _Chip(
            text: formatBytes(item.sizeBytes),
            icon: Icons.sd_storage_outlined,
          ),
          _Chip(text: item.resolvedFolder, icon: Icons.folder_outlined),
          if (item.isDuplicate)
            const _Chip(
              text: 'Duplicate',
              icon: Icons.copy_all_outlined,
              color: Color(0xFFF25F5C),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.icon,
    this.color = const Color(0xFF1F8A8A),
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onSkip,
    required this.onDelete,
    required this.onTag,
    required this.onKeep,
  });

  final VoidCallback onSkip;
  final VoidCallback onDelete;
  final VoidCallback onTag;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _CircleAction(
          icon: Icons.skip_next_outlined,
          color: const Color(0xFFFAB84C),
          onTap: onSkip,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: Icons.delete_outline,
          color: const Color(0xFFF25F5C),
          onTap: onDelete,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: Icons.sell_outlined,
          color: const Color(0xFF4C77E2),
          onTap: onTag,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: Icons.favorite_outline,
          color: const Color(0xFF45C08A),
          onTap: onKeep,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          Text(title, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyQueueCard extends StatelessWidget {
  const _EmptyQueueCard({required this.onOpenTrash});

  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.celebration_outlined,
              size: 64,
              color: Color(0xFF1F8A8A),
            ),
            const SizedBox(height: 8),
            const Text(
              'No cards left in this mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch discovery mode, rescan, or review your trash queue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onOpenTrash,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Open Trash Tab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagMoveAction {
  const _TagMoveAction({required this.tags, required this.folder});

  final List<String> tags;
  final String? folder;
}
