import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';
import '../widgets/media_preview.dart';

class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({required this.onApplyMode, super.key});

  final void Function(DiscoveryMode mode, {String? folder}) onApplyMode;

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 420) {
      return;
    }
    ref.read(sweepControllerProvider.notifier).loadMoreActiveMedia();
  }

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final List<String> folders = state.folders;
    final List<MediaItem> items = state.activePage.items;

    return SweepPage(
      controller: _scrollController,
      eyebrow: 'Explore',
      title: 'Curate in bulk',
      subtitle:
          'Switch discovery modes, preview the media wall, and apply actions across the current set.',
      children: <Widget>[
        SweepReveal(
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Discovery modes',
                  subtitle:
                      'Change what the session and wall are focused on right now.',
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
                        folders.isNotEmpty) {
                      widget.onApplyMode(mode, folder: folders.first);
                      return;
                    }
                    widget.onApplyMode(mode);
                  },
                ),
                if (state.discoveryMode == DiscoveryMode.specificFolder) ...<
                  Widget
                >[
                  const SizedBox(height: 16),
                  SweepSelectField(
                    label: 'Folder',
                    value: state.specificFolder,
                    placeholder: folders.isEmpty
                        ? 'No folders available'
                        : 'Choose a folder',
                    icon: CupertinoIcons.folder,
                    onTap: folders.isEmpty
                        ? () {}
                        : () => _pickFolder(
                            context,
                            folders,
                            state.specificFolder,
                            (String folder) => widget.onApplyMode(
                              DiscoveryMode.specificFolder,
                              folder: folder,
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 12),
                SweepPill(
                  text:
                      '${state.activePage.totalCount} matched • ${items.length} loaded',
                  icon: CupertinoIcons.rectangle_stack_fill,
                  color: theme.colors.info,
                  filled: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 60),
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SweepSectionHeader(
                  title: 'Bulk actions',
                  subtitle:
                      '${state.selectedBulkIds.length} selected in ${state.discoveryMode.label}.',
                  trailing: SweepButton(
                    label: 'Clear',
                    size: SweepButtonSize.compact,
                    variant: SweepButtonVariant.ghost,
                    onPressed: state.selectedBulkIds.isEmpty
                        ? null
                        : controller.clearBulkSelection,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SweepButton(
                        label: 'Delete',
                        icon: CupertinoIcons.trash,
                        variant: SweepButtonVariant.danger,
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : controller.markSelectedForDeletion,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SweepButton(
                        label: 'Tag',
                        icon: CupertinoIcons.tag,
                        variant: SweepButtonVariant.secondary,
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : () => _showTagDialog(context, controller),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SweepButton(
                        label: 'Move',
                        icon: CupertinoIcons.folder,
                        variant: SweepButtonVariant.secondary,
                        onPressed: state.selectedBulkIds.isEmpty
                            ? null
                            : () => _showMoveDialog(context, controller),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          SweepReveal(
            delay: const Duration(milliseconds: 120),
            child: const SweepEmptyState(
              icon: CupertinoIcons.sparkles,
              title: 'No items in this mode',
              body:
                  'Switch discovery modes or rescan the gallery to populate this wall.',
            ),
          )
        else
          SweepReveal(
            delay: const Duration(milliseconds: 120),
            child: Column(
              children: <Widget>[
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final MediaItem item = items[index];
                    final bool selected = state.selectedBulkIds.contains(item.id);

                    return GestureDetector(
                      onTap: () => controller.toggleBulkSelection(item.id),
                      child: AnimatedContainer(
                        duration: theme.motion.component,
                        curve: theme.motion.standard,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(theme.radii.md),
                          border: Border.all(
                            color: selected
                                ? theme.colors.primary
                                : theme.colors.border,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? theme.elevation.glow(theme.colors.primary, 0.55)
                              : const <BoxShadow>[],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(theme.radii.md),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              MediaPreview(
                                item: item,
                                showMetadata: false,
                                thumbnailSize: 320,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: <Color>[
                                      const Color(0xD6060B14),
                                      const Color(0x00000000),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: SweepCheckIndicator(selected: selected),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.resolvedFolder,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typography.bodyStrong.copyWith(
                                        color: theme.colors.textOnAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.kind.label} • ${formatMaybeBytes(item.sizeBytes)}',
                                      style: theme.typography.detail.copyWith(
                                        color: theme.colors.textOnAccent
                                            .withValues(alpha: 0.78),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                if (state.activePage.hasMore)
                  SweepButton(
                    label: 'Load more',
                    icon: CupertinoIcons.chevron_down_circle,
                    expand: true,
                    variant: SweepButtonVariant.secondary,
                    onPressed: controller.loadMoreActiveMedia,
                  )
                else
                  SweepPill(
                    text: 'All matched items are loaded',
                    icon: CupertinoIcons.check_mark_circled_solid,
                    color: theme.colors.success,
                    filled: true,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickFolder(
    BuildContext context,
    List<String> folders,
    String? current,
    ValueChanged<String> onPick,
  ) async {
    final String? folder = await showSweepSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SweepSheetFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'Choose folder',
                subtitle: 'Use a specific collection as the active explore lane.',
              ),
              const SizedBox(height: 16),
              ...folders.map(
                (String folder) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SweepListRow(
                    onTap: () => Navigator.of(context).pop(folder),
                    title: folder,
                    subtitle: folder == current ? 'Current selection' : null,
                    leading: const Icon(CupertinoIcons.folder),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (folder != null) {
      onPick(folder);
    }
  }

  Future<void> _showTagDialog(
    BuildContext context,
    SweepController controller,
  ) async {
    final TextEditingController tagController = TextEditingController();
    await showSweepDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SweepDialogFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'Assign tag',
                subtitle: 'Apply one lightweight tag to the current bulk selection.',
              ),
              const SizedBox(height: 16),
              SweepTextField(
                label: 'Tag',
                placeholder: 'Enter a tag',
                controller: tagController,
                prefix: const Icon(CupertinoIcons.tag),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SweepButton(
                      label: 'Cancel',
                      variant: SweepButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SweepButton(
                      label: 'Apply',
                      onPressed: () {
                        controller.bulkAssignTag(tagController.text);
                        Navigator.of(context).pop();
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

  Future<void> _showMoveDialog(
    BuildContext context,
    SweepController controller,
  ) async {
    final TextEditingController folderController = TextEditingController();
    await showSweepDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SweepDialogFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'Move selection',
                subtitle:
                    'Save the target folder in Sweep and attempt a local device move.',
              ),
              const SizedBox(height: 16),
              SweepTextField(
                label: 'Folder',
                placeholder: 'Pictures/Travel',
                controller: folderController,
                prefix: const Icon(CupertinoIcons.folder),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SweepButton(
                      label: 'Cancel',
                      variant: SweepButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SweepButton(
                      label: 'Apply',
                      onPressed: () {
                        controller.bulkMoveToFolder(folderController.text);
                        Navigator.of(context).pop();
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
}
