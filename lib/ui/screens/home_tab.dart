import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';
import '../widgets/storage_meter.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({
    required this.onOpenSwipe,
    required this.onApplyMode,
    super.key,
  });

  final VoidCallback onOpenSwipe;
  final void Function(DiscoveryMode mode, {String? folder}) onApplyMode;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  ScanScope _scope = ScanScope.entireGallery;
  final TextEditingController _folderController = TextEditingController();

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final GallerySummary insights = state.summary;
    final List<CleanupSuggestion> suggestions = state.cleanupSuggestions;

    return SweepPage(
      eyebrow: 'Command Center',
      title: 'Swipe your gallery clean',
      subtitle:
          'Run targeted scans, see the impact instantly, and jump straight into the cleanup session.',
      trailing: SweepButton(
        label: 'Session',
        icon: CupertinoIcons.arrow_right,
        size: SweepButtonSize.compact,
        variant: SweepButtonVariant.secondary,
        onPressed: widget.onOpenSwipe,
      ),
      children: <Widget>[
        SweepReveal(
          child: _HeroPanel(insights: insights, onOpenSwipe: widget.onOpenSwipe),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 60),
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Scan engine',
                  subtitle: 'Pick a scope, rescan, and open a focused session.',
                ),
                const SizedBox(height: 16),
                SweepSelector<ScanScope>(
                  options: ScanScope.values
                      .map(
                        (ScanScope scope) => SweepChoice<ScanScope>(
                          value: scope,
                          label: scope.label,
                          icon: _scanScopeIcon(scope),
                        ),
                      )
                      .toList(),
                  selected: _scope,
                  onSelected: (ScanScope value) {
                    setState(() {
                      _scope = value;
                    });
                  },
                ),
                if (_scope == ScanScope.specificFolder) ...<Widget>[
                  const SizedBox(height: 14),
                  SweepTextField(
                    label: 'Folder name',
                    placeholder: 'e.g. WhatsApp Images',
                    controller: _folderController,
                    prefix: Icon(
                      CupertinoIcons.folder,
                      size: 18,
                      color: theme.colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SweepButton(
                  label: state.isLoading
                      ? 'Scanning...'
                      : 'Scan and open session',
                  icon: CupertinoIcons.search,
                  expand: true,
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await controller.scanGallery(
                            scope: _scope,
                            specificFolder: _scope == ScanScope.specificFolder
                                ? _folderController.text.trim()
                                : null,
                          );
                          if (!mounted) {
                            return;
                          }
                          widget.onOpenSwipe();
                        },
                ),
                if (state.statusMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  SweepPill(
                    text: state.statusMessage!,
                    icon: CupertinoIcons.waveform_path_ecg,
                    color: theme.colors.info,
                    filled: true,
                  ),
                ],
                if (insights.isPartial) ...<Widget>[
                  const SizedBox(height: 12),
                  SweepPill(
                    text:
                        '${insights.unresolvedSizeCount} items still refining in the background',
                    icon: CupertinoIcons.timer,
                    color: theme.colors.warning,
                    filled: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 110),
          child: StorageMeter(
            totalBytes: insights.totalSizeBytes,
            reclaimableBytes: insights.potentialFreedBytes,
          ),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 160),
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Storage insights',
                  subtitle: 'A snapshot of the current index and likely wins.',
                ),
                const SizedBox(height: 14),
                _InsightRow(
                  label: 'Total indexed media',
                  value: '${insights.totalMediaCount}',
                ),
                _InsightRow(
                  label: 'Storage footprint',
                  value: formatBytes(insights.totalSizeBytes),
                ),
                _InsightRow(
                  label: 'Duplicates detected',
                  value: '${insights.duplicateCount}',
                ),
                _InsightRow(
                  label: 'Largest videos tracked',
                  value: '${insights.largestVideos.length}',
                ),
                _InsightRow(
                  label: 'Folders mapped',
                  value: '${insights.folderUsage.length}',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 220),
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Suggested cleanup paths',
                  subtitle:
                      'Shortcuts into modes with immediate storage or clarity impact.',
                ),
                const SizedBox(height: 16),
                ...suggestions.map(
                  (CleanupSuggestion suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SuggestionTile(
                      suggestion: suggestion,
                      onStart: () => widget.onApplyMode(suggestion.mode),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static IconData _scanScopeIcon(ScanScope scope) {
    switch (scope) {
      case ScanScope.entireGallery:
        return CupertinoIcons.rectangle_stack;
      case ScanScope.specificFolder:
        return CupertinoIcons.folder;
      case ScanScope.cameraRollOnly:
        return CupertinoIcons.camera;
      case ScanScope.whatsappMedia:
        return CupertinoIcons.chat_bubble_2;
      case ScanScope.screenshots:
        return CupertinoIcons.device_phone_portrait;
      case ScanScope.downloads:
        return CupertinoIcons.arrow_down_circle;
    }
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.insights, required this.onOpenSwipe});

  final GallerySummary insights;
  final VoidCallback onOpenSwipe;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      gradient: theme.heroGradient,
      borderRadius: BorderRadius.circular(theme.radii.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SweepPill(
            text: '${insights.totalMediaCount} items indexed',
            icon: CupertinoIcons.sparkles,
            color: theme.colors.textOnAccent,
            filled: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Fast enough to feel playful.\nFocused enough to be useful.',
            style: theme.typography.display.copyWith(
              color: theme.colors.textOnAccent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${formatBytes(insights.totalSizeBytes)} across the current gallery index'
            '${insights.isPartial ? ' so far.' : '.'}',
            style: theme.typography.detail.copyWith(
              color: theme.colors.textOnAccent.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          SweepButton(
            label: 'Start swipe session',
            icon: CupertinoIcons.arrow_right_circle_fill,
            size: SweepButtonSize.hero,
            expand: true,
            onPressed: onOpenSwipe,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: theme.typography.detail),
            ),
            Text(value, style: theme.typography.bodyStrong),
          ],
        ),
        if (showDivider) ...<Widget>[
          const SizedBox(height: 12),
          Container(height: 1, color: theme.colors.border),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.onStart,
  });

  final CleanupSuggestion suggestion;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      tone: SweepSurfaceTone.muted,
      shadows: false,
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: theme.heroGradient,
              borderRadius: BorderRadius.circular(theme.radii.md),
            ),
            child: Icon(
              suggestion.mode.icon,
              color: theme.colors.textOnAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(suggestion.title, style: theme.typography.bodyStrong),
                const SizedBox(height: 4),
                Text(suggestion.subtitle, style: theme.typography.detail),
                const SizedBox(height: 6),
                Text(
                  '${suggestion.itemCount} items • ${formatBytes(suggestion.estimatedBytes)}',
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SweepButton(
            label: 'Start',
            size: SweepButtonSize.compact,
            variant: SweepButtonVariant.secondary,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
