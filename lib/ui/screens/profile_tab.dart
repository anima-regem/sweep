import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final StorageInsights insights = controller.storageInsights();

    final int processed = state.decisions.length;
    final int kept = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.keep)
        .length;
    final int deleted = state.decisions.values
        .where((SwipeDecision decision) => decision == SwipeDecision.delete)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Sweep Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text('Smooth. Satisfying. Minimal. Playful.'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    Chip(label: Text('Local-only processing')),
                    Chip(label: Text('No cloud upload')),
                    Chip(label: Text('Android-first MVP')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Metrics for Success',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _MetricRow(label: 'Photos processed', value: '$processed'),
                _MetricRow(label: 'Kept', value: '$kept'),
                _MetricRow(label: 'Marked for deletion', value: '$deleted'),
                _MetricRow(
                  label: 'Storage cleaned (session)',
                  value: formatBytes(state.lastSessionFreedBytes),
                ),
                _MetricRow(
                  label: 'Total storage indexed',
                  value: formatBytes(insights.totalSizeBytes),
                ),
                _MetricRow(
                  label: 'Sessions completed',
                  value: '${state.sessionsCompleted}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'App Settings',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rescan Entire Gallery'),
                  subtitle: const Text(
                    'Refresh media index and re-run duplicate detection',
                  ),
                  trailing: FilledButton(
                    onPressed: () =>
                        controller.scanGallery(scope: ScanScope.entireGallery),
                    child: const Text('Rescan'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permissions Fallback'),
                  subtitle: const Text(
                    'If permissions are denied, Sweep uses a generated demo index '
                    'so every flow still works.',
                  ),
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
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
