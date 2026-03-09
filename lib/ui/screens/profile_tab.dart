import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final SweepState state = ref.watch(sweepControllerProvider);
    final GallerySummary insights = state.summary;

    final int processed = state.decisions.length;
    final int kept = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.keep)
        .length;
    final int deleted = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return SweepPage(
      eyebrow: 'Profile',
      title: 'Sweep metrics',
      subtitle:
          'Private by default, local in execution, and designed to make cleanup repeatable.',
      children: <Widget>[
        SweepReveal(
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                SweepSectionHeader(
                  title: 'Product posture',
                  subtitle: 'The fundamentals that shape every decision in the current app.',
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    SweepPill(
                      text: 'Local-only processing',
                      icon: CupertinoIcons.lock_shield_fill,
                      filled: true,
                    ),
                    SweepPill(
                      text: 'No cloud upload',
                      icon: CupertinoIcons.cloud,
                      filled: true,
                    ),
                    SweepPill(
                      text: 'Android-first MVP',
                      icon: CupertinoIcons.device_phone_portrait,
                      filled: true,
                    ),
                  ],
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
                const SweepSectionHeader(
                  title: 'Success metrics',
                  subtitle: 'Session outcomes and archive progress in one place.',
                ),
                const SizedBox(height: 16),
                _MetricRow(label: 'Photos processed', value: '$processed'),
                _MetricRow(label: 'Kept', value: '$kept'),
                _MetricRow(label: 'Marked for deletion', value: '$deleted'),
                _MetricRow(
                  label: 'Storage cleaned (last session)',
                  value: formatBytes(state.lastSessionFreedBytes),
                ),
                _MetricRow(
                  label: 'Total storage indexed',
                  value: formatBytes(insights.totalSizeBytes),
                ),
                _MetricRow(
                  label: 'Background refinement',
                  value: insights.isPartial
                      ? '${insights.unresolvedSizeCount} pending'
                      : 'Complete',
                ),
                _MetricRow(
                  label: 'Sessions completed',
                  value: '${state.sessionsCompleted}',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SweepReveal(
          delay: const Duration(milliseconds: 120),
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'App actions',
                  subtitle:
                      'Operational controls that reset or refresh the current index.',
                ),
                const SizedBox(height: 16),
                SweepListRow(
                  title: 'Rescan entire gallery',
                  subtitle:
                      'Refresh media index and rerun duplicate detection.',
                  leading: const Icon(CupertinoIcons.refresh),
                  trailing: SweepButton(
                    label: 'Rescan',
                    size: SweepButtonSize.compact,
                    onPressed: () =>
                        controller.scanGallery(scope: ScanScope.entireGallery),
                  ),
                ),
                const SizedBox(height: 12),
                const SweepListRow(
                  title: 'Permissions fallback',
                  subtitle:
                      'If access is denied, Sweep falls back to a generated local demo index so every flow still works.',
                  leading: Icon(CupertinoIcons.shield_lefthalf_fill),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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
