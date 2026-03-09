import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';
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
    final SweepState state = ref.watch(sweepControllerProvider);
    final List<MediaItem> trash = state.trashPage.items;

    if (_selected.any(
      (String id) => !trash.any((MediaItem item) => item.id == id),
    )) {
      _selected.removeWhere(
        (String id) => !trash.any((MediaItem item) => item.id == id),
      );
    }

    final int totalBytes = state.summary.potentialFreedBytes;

    return SweepPage(
      eyebrow: 'Review Queue',
      title: 'Trash checkpoint',
      subtitle:
          'Nothing is final until you confirm it here. Restore or commit the dangerous actions.',
      children: <Widget>[
        SweepReveal(
          child: SweepSurface(
            tone: SweepSurfaceTone.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Deletion review',
                  subtitle:
                      'Review volume, select what to restore, and confirm permanent removal only when ready.',
                ),
                const SizedBox(height: 14),
                Text(
                  '${state.trashPage.totalCount} files queued • ${formatBytes(totalBytes)} at risk',
                  style: SweepTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SweepButton(
                        label: 'Restore selected',
                        icon: CupertinoIcons.refresh,
                        variant: SweepButtonVariant.secondary,
                        onPressed: _selected.isEmpty
                            ? null
                            : () {
                                controller.restoreItems(_selected);
                                setState(_selected.clear);
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SweepButton(
                        label: 'Delete selected',
                        icon: CupertinoIcons.trash,
                        variant: SweepButtonVariant.danger,
                        onPressed: _selected.isEmpty
                            ? null
                            : () => _confirmDelete(
                                context,
                                count: _selected.length,
                                onConfirm: () async {
                                  await controller.permanentlyDeleteItems(
                                    _selected,
                                  );
                                  setState(_selected.clear);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SweepButton(
                  label: 'Delete entire queue',
                  icon: CupertinoIcons.exclamationmark_triangle,
                  expand: true,
                  variant: SweepButtonVariant.ghost,
                  onPressed: trash.isEmpty
                      ? null
                      : () => _confirmDelete(
                          context,
                          count: trash.length,
                          onConfirm: () async {
                            await controller.permanentlyDeleteItems(
                              trash.map((MediaItem item) => item.id).toSet(),
                            );
                            setState(_selected.clear);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (trash.isEmpty)
          const SweepReveal(
            delay: Duration(milliseconds: 70),
            child: SweepEmptyState(
              icon: CupertinoIcons.sparkles,
              title: 'Trash is empty',
              body:
                  'Swipe left inside Session to queue media for review and deletion.',
            ),
          )
        else
          SweepReveal(
            delay: const Duration(milliseconds: 70),
            child: Column(
              children: <Widget>[
                ...trash.map(
                  (MediaItem item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MediaTile(
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
                ),
                if (state.trashPage.hasMore)
                  SweepButton(
                    label: 'Load more queued items',
                    icon: CupertinoIcons.chevron_down_circle,
                    expand: true,
                    variant: SweepButtonVariant.secondary,
                    onPressed: controller.loadMoreTrashItems,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required int count,
    required Future<void> Function() onConfirm,
  }) async {
    await showSweepDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SweepDialogFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SweepSectionHeader(
                title: 'Permanent delete',
                subtitle:
                    'This removes the items from the Sweep index and attempts to delete real gallery assets when available.',
              ),
              const SizedBox(height: 16),
              Text(
                'Continue with $count file${count == 1 ? '' : 's'}?',
                style: SweepTheme.of(context).typography.bodyStrong,
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
                      label: 'Delete',
                      variant: SweepButtonVariant.danger,
                      onPressed: () async {
                        final NavigatorState navigator = Navigator.of(context);
                        await onConfirm();
                        navigator.pop();
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
