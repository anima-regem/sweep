import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';
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
        await showSweepDialog<void>(
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

    final List<MediaItem> queue = state.sessionQueue;
    final MediaItem? current = queue.isNotEmpty ? queue.first : null;
    final MediaItem? next = queue.length > 1 ? queue[1] : null;

    return SweepPage(
      eyebrow: 'Session',
      title: 'Live swipe lane',
      subtitle:
          'Move fast through the active discovery mode with gesture-driven actions and a review queue.',
      trailing: SweepPill(
        text: '${queue.length} pending',
        icon: CupertinoIcons.waveform_path,
        filled: true,
      ),
      children: <Widget>[
        if (current == null)
          SweepReveal(
            child: SweepEmptyState(
              icon: CupertinoIcons.sparkles,
              title: 'No cards left in this mode',
              body:
                  'Switch discovery modes, rescan the gallery, or open the review queue.',
              action: SweepButton(
                label: 'Open review queue',
                icon: CupertinoIcons.trash,
                expand: true,
                onPressed: widget.onOpenTrash,
              ),
            ),
          )
        else
          SweepReveal(
            child: Column(
              children: <Widget>[
                SwipeDeck(
                  current: current,
                  next: next,
                  onTap: () => _openCardActions(current),
                  onSwipe: (MediaItem item, SwipeDirection direction) {
                    _handleSwipe(item, direction);
                  },
                ),
                const SizedBox(height: 16),
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
          ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 60),
          child: _SessionSummary(state: state, queueCount: queue.length),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 120),
          child: _ModePanel(
            state: state,
            controller: controller,
            onPickFolder: () => _pickFolder(context, controller, state),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFolder(
    BuildContext context,
    SweepController controller,
    SweepState state,
  ) async {
    final List<String> folders = controller.folders();
    if (folders.isEmpty) {
      return;
    }

    final String? folder = await showSweepSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SweepSheetFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'Specific folder',
                subtitle: 'Choose which folder feeds the current swipe lane.',
              ),
              const SizedBox(height: 16),
              ...folders.map(
                (String folder) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SweepListRow(
                    title: folder,
                    subtitle: folder == state.specificFolder
                        ? 'Current folder'
                        : null,
                    leading: const Icon(CupertinoIcons.folder),
                    onTap: () => Navigator.of(context).pop(folder),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (folder != null) {
      controller.setDiscoveryMode(
        DiscoveryMode.specificFolder,
        folderName: folder,
      );
    }
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
    await showSweepSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SweepSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SweepSectionHeader(
                title: item.path.split('/').last,
                subtitle:
                    '${formatDate(item.createdAt)} • ${formatMaybeBytes(item.sizeBytes)} • ${item.resolvedFolder}',
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SweepButton(
                      label: 'Tag / move',
                      icon: CupertinoIcons.tag,
                      variant: SweepButtonVariant.secondary,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _handleSwipe(item, SwipeDirection.up);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SweepButton(
                      label: 'Delete',
                      icon: CupertinoIcons.trash,
                      variant: SweepButtonVariant.danger,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleSwipe(item, SwipeDirection.left);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SweepButton(
                      label: 'Keep',
                      icon: CupertinoIcons.heart,
                      variant: SweepButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleSwipe(item, SwipeDirection.right);
                      },
                    ),
                  ),
                ],
              ),
            ],
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
    String? selectedFolder = item.resolvedFolder;
    final TextEditingController tagController = TextEditingController();

    final _TagMoveAction? result = await showSweepSheet<_TagMoveAction>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                return SweepSheetFrame(
                  maxWidth: 760,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SweepSectionHeader(
                          title: 'Tag and organize',
                          subtitle:
                              'Attach labels, choose a target folder, and continue the session.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: state.customTags
                              .map(
                                (String tag) => SweepPill(
                                  text: tag,
                                  icon: CupertinoIcons.tag_fill,
                                  color: SweepTheme.of(context).colors.info,
                                  selected: selectedTags.contains(tag),
                                  onTap: () {
                                    setModalState(() {
                                      if (selectedTags.contains(tag)) {
                                        selectedTags.remove(tag);
                                      } else {
                                        selectedTags.add(tag);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SweepTextField(
                                label: 'Create tag',
                                placeholder: 'Archive / Receipts / Family',
                                controller: tagController,
                                prefix: const Icon(CupertinoIcons.tag),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: SweepButton(
                                label: 'Add',
                                variant: SweepButtonVariant.secondary,
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
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Move to folder',
                          style: SweepTheme.of(context).typography.caption,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: controller.folders().map((String folder) {
                            return SweepPill(
                              text: folder,
                              icon: CupertinoIcons.folder_fill,
                              color: SweepTheme.of(context).colors.warning,
                              selected: selectedFolder == folder,
                              onTap: () {
                                setModalState(() {
                                  selectedFolder = folder;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        SweepButton(
                          label: 'Apply tag / move',
                          icon: CupertinoIcons.check_mark_circled_solid,
                          expand: true,
                          onPressed: () {
                            Navigator.of(context).pop(
                              _TagMoveAction(
                                tags: selectedTags.toList(),
                                folder: selectedFolder,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );

    tagController.dispose();
    return result;
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({
    required this.state,
    required this.controller,
    required this.onPickFolder,
  });

  final SweepState state;
  final SweepController controller;
  final VoidCallback onPickFolder;

  @override
  Widget build(BuildContext context) {
    return SweepSurface(
      tone: SweepSurfaceTone.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SweepSectionHeader(
            title: 'Discovery lane',
            subtitle: 'Change the active session mode without leaving the swipe flow.',
          ),
          const SizedBox(height: 16),
          SweepSelector<DiscoveryMode>(
            options: DiscoveryMode.values
                .map(
                  (DiscoveryMode mode) => SweepChoice<DiscoveryMode>(
                    value: mode,
                    label: mode.label,
                    icon: mode.icon,
                  ),
                )
                .toList(),
            selected: state.discoveryMode,
            onSelected: (DiscoveryMode mode) {
              if (mode == DiscoveryMode.specificFolder &&
                  state.specificFolder == null &&
                  controller.folders().isNotEmpty) {
                controller.setDiscoveryMode(
                  mode,
                  folderName: controller.folders().first,
                );
                return;
              }
              controller.setDiscoveryMode(mode);
            },
          ),
          if (state.discoveryMode == DiscoveryMode.specificFolder) ...<Widget>[
            const SizedBox(height: 16),
            SweepSelectField(
              label: 'Folder',
              value: state.specificFolder,
              placeholder: 'Choose a folder',
              icon: CupertinoIcons.folder,
              onTap: onPickFolder,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.state, required this.queueCount});

  final SweepState state;
  final int queueCount;

  @override
  Widget build(BuildContext context) {
    final int trashCount = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            title: 'Pending',
            value: '$queueCount',
            icon: CupertinoIcons.rectangle_stack_fill,
            color: SweepTheme.of(context).colors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Trash queue',
            value: '$trashCount',
            icon: CupertinoIcons.trash_fill,
            color: SweepTheme.of(context).colors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Sessions',
            value: '${state.sessionsCompleted}',
            icon: CupertinoIcons.sparkles,
            color: SweepTheme.of(context).colors.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      tone: SweepSurfaceTone.raised,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          SweepPill(
            text: formatDate(item.createdAt),
            icon: CupertinoIcons.calendar,
            color: theme.colors.info,
            filled: true,
          ),
          SweepPill(
            text: formatMaybeBytes(item.sizeBytes),
            icon: CupertinoIcons.archivebox,
            color: theme.colors.primary,
            filled: true,
          ),
          SweepPill(
            text: item.resolvedFolder,
            icon: CupertinoIcons.folder,
            color: theme.colors.warning,
            filled: true,
          ),
          if (item.isDuplicate)
            SweepPill(
              text: 'Duplicate',
              icon: CupertinoIcons.square_on_square,
              color: theme.colors.danger,
              filled: true,
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
          icon: CupertinoIcons.forward,
          color: SweepTheme.of(context).colors.warning,
          onTap: onSkip,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: CupertinoIcons.trash,
          color: SweepTheme.of(context).colors.danger,
          onTap: onDelete,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: CupertinoIcons.tag,
          color: SweepTheme.of(context).colors.info,
          onTap: onTag,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          icon: CupertinoIcons.heart,
          color: SweepTheme.of(context).colors.success,
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
    final SweepThemeData theme = SweepTheme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(theme.radii.md),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      tone: SweepSurfaceTone.muted,
      shadows: false,
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.typography.headline.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.typography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TagMoveAction {
  const _TagMoveAction({required this.tags, required this.folder});

  final List<String> tags;
  final String? folder;
}
