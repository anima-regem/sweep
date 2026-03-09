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
  const SwipeTab({
    required this.onOpenTrash,
    required this.onCloseSession,
    super.key,
  });

  final VoidCallback onOpenTrash;
  final VoidCallback onCloseSession;

  @override
  ConsumerState<SwipeTab> createState() => _SwipeTabState();
}

class _SwipeTabState extends ConsumerState<SwipeTab> {
  bool _dialogVisible = false;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final EdgeInsets safePadding = MediaQuery.paddingOf(context);
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
    final int trashCount = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.md,
              safePadding.top + 76,
              theme.spacing.md,
              safePadding.bottom + 170,
            ),
            child: AnimatedSwitcher(
              duration: theme.motion.component,
              switchInCurve: theme.motion.emphasized,
              switchOutCurve: theme.motion.standard,
              child: current == null
                  ? _SessionEmptyState(
                      key: const ValueKey<String>('session-empty'),
                      onOpenTrash: widget.onOpenTrash,
                      onOpenModes: () =>
                          _openModeSheet(context, controller, state),
                      onCloseSession: widget.onCloseSession,
                    )
                  : Center(
                      key: ValueKey<String>(current.id),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: SwipeDeck(
                          current: current,
                          next: next,
                          onTap: () => _openCardActions(current),
                          onSwipe: (MediaItem item, SwipeDirection direction) {
                            _handleSwipe(item, direction);
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          top: safePadding.top + 12,
          left: theme.spacing.gutter,
          right: theme.spacing.gutter,
          child: KeyedSubtree(
            key: const ValueKey<String>('session-top-strip'),
            child: _SessionTopBar(
              state: state,
              queueCount: queue.length,
              trashCount: trashCount,
              onCloseSession: widget.onCloseSession,
              onOpenModes: () => _openModeSheet(context, controller, state),
              onOpenTrash: widget.onOpenTrash,
            ),
          ),
        ),
        if (current != null)
          Positioned(
            left: theme.spacing.gutter,
            right: theme.spacing.gutter,
            bottom: safePadding.bottom + 126,
            child: _SessionDeckInfo(
              item: current,
              onOpenActions: () => _openCardActions(current),
            ),
          ),
        Positioned(
          left: theme.spacing.sm,
          right: theme.spacing.sm,
          bottom: safePadding.bottom + theme.spacing.sm,
          child: KeyedSubtree(
            key: const ValueKey<String>('session-bottom-rail'),
            child: _SessionBottomRail(
              state: state,
              queueCount: queue.length,
              trashCount: trashCount,
              current: current,
              onOpenTrash: widget.onOpenTrash,
              onOpenModes: () => _openModeSheet(context, controller, state),
              onSkip: current == null
                  ? null
                  : () => _handleSwipe(current, SwipeDirection.down),
              onDelete: current == null
                  ? null
                  : () => _handleSwipe(current, SwipeDirection.left),
              onTag: current == null
                  ? null
                  : () => _handleSwipe(current, SwipeDirection.up),
              onKeep: current == null
                  ? null
                  : () => _handleSwipe(current, SwipeDirection.right),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openModeSheet(
    BuildContext context,
    SweepController controller,
    SweepState state,
  ) async {
    await showSweepSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SweepSheetFrame(
          maxWidth: 760,
          child: _ModeSheetContent(
            state: state,
            controller: controller,
            onPickFolder: () => _pickFolder(context, controller, state),
          ),
        );
      },
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
                title: item.displayName,
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

class _SessionTopBar extends StatelessWidget {
  const _SessionTopBar({
    required this.state,
    required this.queueCount,
    required this.trashCount,
    required this.onCloseSession,
    required this.onOpenModes,
    required this.onOpenTrash,
  });

  final SweepState state;
  final int queueCount;
  final int trashCount;
  final VoidCallback onCloseSession;
  final VoidCallback onOpenModes;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Row(
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('session-exit-button'),
          child: _SessionIconButton(
            icon: CupertinoIcons.chevron_left,
            label: 'Exit session',
            onTap: onCloseSession,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onOpenModes,
            child: SweepSurface(
              tone: SweepSurfaceTone.raised,
              blur: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(
                    state.discoveryMode.icon,
                    size: 18,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Session lane', style: theme.typography.caption),
                        const SizedBox(height: 2),
                        Text(
                          state.discoveryMode == DiscoveryMode.specificFolder
                              ? (state.specificFolder ?? 'Specific folder')
                              : state.discoveryMode.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.label.copyWith(
                            color: theme.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$queueCount',
                    style: theme.typography.label.copyWith(
                      color: theme.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        KeyedSubtree(
          key: const ValueKey<String>('session-top-review-button'),
          child: _SessionIconButton(
            icon: CupertinoIcons.trash,
            label: 'Open review queue',
            badge: trashCount == 0 ? null : '$trashCount',
            highlight: trashCount == 0
                ? theme.colors.info
                : theme.colors.danger,
            onTap: onOpenTrash,
          ),
        ),
      ],
    );
  }
}

class _SessionDeckInfo extends StatelessWidget {
  const _SessionDeckInfo({required this.item, required this.onOpenActions});

  final MediaItem item;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return GestureDetector(
      onTap: onOpenActions,
      child: SweepSurface(
        tone: SweepSurfaceTone.raised,
        blur: false,
        shadows: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.title.copyWith(
                      color: theme.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.resolvedFolder} • ${formatDate(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.detail,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatMaybeBytes(item.sizeBytes),
                  style: theme.typography.label.copyWith(
                    color: theme.colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.isDuplicate ? 'Duplicate' : 'Open actions',
                  style: theme.typography.caption.copyWith(
                    color: item.isDuplicate
                        ? theme.colors.danger
                        : theme.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionBottomRail extends StatelessWidget {
  const _SessionBottomRail({
    required this.state,
    required this.queueCount,
    required this.trashCount,
    required this.current,
    required this.onOpenTrash,
    required this.onOpenModes,
    required this.onSkip,
    required this.onDelete,
    required this.onTag,
    required this.onKeep,
  });

  final SweepState state;
  final int queueCount;
  final int trashCount;
  final MediaItem? current;
  final VoidCallback onOpenTrash;
  final VoidCallback onOpenModes;
  final VoidCallback? onSkip;
  final VoidCallback? onDelete;
  final VoidCallback? onTag;
  final VoidCallback? onKeep;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      tone: SweepSurfaceTone.raised,
      blur: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _StatBadge(
                key: const ValueKey<String>('session-stat-pending'),
                label: 'Pending',
                value: '$queueCount',
                color: theme.colors.info,
              ),
              _StatBadge(
                key: const ValueKey<String>('session-stat-trash'),
                label: 'Trash',
                value: '$trashCount',
                color: theme.colors.danger,
                onTap: onOpenTrash,
                semanticsLabel: 'Open review queue',
              ),
              _StatBadge(
                key: const ValueKey<String>('session-stat-sessions'),
                label: 'Sessions',
                value: '${state.sessionsCompleted}',
                color: theme.colors.primary,
              ),
              _StatBadge(
                key: const ValueKey<String>('session-stat-mode'),
                label: 'Mode',
                value: state.discoveryMode == DiscoveryMode.specificFolder
                    ? 'Folder'
                    : state.discoveryMode.label,
                color: theme.colors.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (current == null)
            Row(
              children: <Widget>[
                Expanded(
                  child: SweepButton(
                    label: 'Review queue',
                    icon: CupertinoIcons.trash,
                    variant: SweepButtonVariant.secondary,
                    onPressed: onOpenTrash,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SweepButton(
                    label: 'Change mode',
                    icon: CupertinoIcons.slider_horizontal_3,
                    onPressed: onOpenModes,
                  ),
                ),
              ],
            )
          else
            _ActionButtons(
              onSkip: onSkip,
              onDelete: onDelete,
              onTag: onTag,
              onKeep: onKeep,
            ),
        ],
      ),
    );
  }
}

class _ModeSheetContent extends StatelessWidget {
  const _ModeSheetContent({
    required this.state,
    required this.controller,
    required this.onPickFolder,
  });

  final SweepState state;
  final SweepController controller;
  final VoidCallback onPickFolder;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final int trashCount = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SweepSectionHeader(
          title: 'Session controls',
          subtitle:
              'Change discovery lanes without leaving the immersive swipe view.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SweepPill(
              text: '${state.sessionQueue.length} pending',
              icon: CupertinoIcons.rectangle_stack_fill,
              color: theme.colors.info,
              filled: true,
            ),
            SweepPill(
              text: '$trashCount in review',
              icon: CupertinoIcons.trash_fill,
              color: theme.colors.danger,
              filled: true,
            ),
            SweepPill(
              text: '${state.sessionsCompleted} sessions',
              icon: CupertinoIcons.sparkles,
              color: theme.colors.primary,
              filled: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
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
    );
  }
}

class _SessionIconButton extends StatelessWidget {
  const _SessionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? highlight;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final Color tint = highlight ?? theme.colors.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SweepSurface(
          tone: SweepSurfaceTone.raised,
          blur: false,
          shadows: false,
          padding: const EdgeInsets.all(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Icon(icon, size: 18, color: tint),
              if (badge != null)
                Positioned(
                  right: -6,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(theme.radii.pill),
                    ),
                    child: Text(
                      badge!,
                      style: theme.typography.caption.copyWith(
                        color: theme.colors.textOnAccent,
                      ),
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

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onSkip,
    required this.onDelete,
    required this.onTag,
    required this.onKeep,
  });

  final VoidCallback? onSkip;
  final VoidCallback? onDelete;
  final VoidCallback? onTag;
  final VoidCallback? onKeep;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Row(
      children: <Widget>[
        _ActionPuck(
          label: 'Skip',
          icon: CupertinoIcons.forward,
          color: theme.colors.warning,
          onTap: onSkip,
        ),
        const SizedBox(width: 10),
        _ActionPuck(
          label: 'Delete',
          icon: CupertinoIcons.trash,
          color: theme.colors.danger,
          onTap: onDelete,
        ),
        const SizedBox(width: 10),
        _ActionPuck(
          label: 'Tag',
          icon: CupertinoIcons.tag,
          color: theme.colors.info,
          onTap: onTag,
        ),
        const SizedBox(width: 10),
        _ActionPuck(
          label: 'Keep',
          icon: CupertinoIcons.heart,
          color: theme.colors.success,
          onTap: onKeep,
        ),
      ],
    );
  }
}

class _ActionPuck extends StatelessWidget {
  const _ActionPuck({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: theme.motion.micro,
          curve: theme.motion.standard,
          height: 74,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(theme.radii.md),
            border: Border.all(color: color.withValues(alpha: 0.28)),
            boxShadow: onTap == null
                ? const <BoxShadow>[]
                : theme.elevation.glow(color, 0.24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: onTap == null ? color.withValues(alpha: 0.44) : color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.typography.caption.copyWith(
                  color: onTap == null ? color.withValues(alpha: 0.44) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    final Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: theme.typography.label.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: theme.typography.caption.copyWith(color: color)),
        ],
      ),
    );

    if (onTap == null) {
      return badge;
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      ),
    );
  }
}

class _SessionEmptyState extends StatelessWidget {
  const _SessionEmptyState({
    required this.onOpenTrash,
    required this.onOpenModes,
    required this.onCloseSession,
    super.key,
  });

  final VoidCallback onOpenTrash;
  final VoidCallback onOpenModes;
  final VoidCallback onCloseSession;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SweepSurface(
          tone: SweepSurfaceTone.raised,
          blur: false,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'This session lane is clear',
                subtitle:
                    'Switch to another discovery mode, review the delete queue, or step back to the main library.',
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SweepButton(
                      label: 'Change mode',
                      icon: CupertinoIcons.slider_horizontal_3,
                      onPressed: onOpenModes,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SweepButton(
                      label: 'Review queue',
                      icon: CupertinoIcons.trash,
                      variant: SweepButtonVariant.secondary,
                      onPressed: onOpenTrash,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SweepButton(
                label: 'Return to library',
                icon: CupertinoIcons.chevron_left,
                expand: true,
                variant: SweepButtonVariant.ghost,
                onPressed: onCloseSession,
              ),
            ],
          ),
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
