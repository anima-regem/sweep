import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
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
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final StorageInsights insights = controller.storageInsights();
    final List<CleanupSuggestion> suggestions = controller.suggestions();

    return RefreshIndicator(
      onRefresh: () => controller.scanGallery(
        scope: _scope,
        specificFolder: _scope == ScanScope.specificFolder
            ? _folderController.text.trim()
            : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: <Widget>[
          _HeroCard(insights: insights, onOpenSwipe: widget.onOpenSwipe),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Gallery Scan Engine',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<ScanScope>(
                  initialValue: _scope,
                  decoration: const InputDecoration(
                    labelText: 'Scan Mode',
                    border: OutlineInputBorder(),
                  ),
                  items: ScanScope.values
                      .map(
                        (ScanScope scope) => DropdownMenuItem<ScanScope>(
                          value: scope,
                          child: Text(scope.label),
                        ),
                      )
                      .toList(),
                  onChanged: (ScanScope? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _scope = value;
                    });
                  },
                ),
                if (_scope == ScanScope.specificFolder) ...<Widget>[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _folderController,
                    decoration: const InputDecoration(
                      labelText: 'Folder Name',
                      hintText: 'e.g. WhatsApp Images',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                await controller.scanGallery(
                                  scope: _scope,
                                  specificFolder:
                                      _scope == ScanScope.specificFolder
                                      ? _folderController.text.trim()
                                      : null,
                                );
                                if (!mounted) {
                                  return;
                                }
                                widget.onOpenSwipe();
                              },
                        icon: const Icon(Icons.search),
                        label: const Text('Scan + Start Session'),
                      ),
                    ),
                  ],
                ),
                if (state.statusMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    state.statusMessage!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorageMeter(
            totalBytes: insights.totalSizeBytes,
            reclaimableBytes: insights.potentialFreedBytes,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Storage Insights',
            child: Column(
              children: <Widget>[
                _InsightRow(
                  label: 'Total media count',
                  value: '${insights.totalMediaCount}',
                ),
                _InsightRow(
                  label: 'Total storage used',
                  value: formatBytes(insights.totalSizeBytes),
                ),
                _InsightRow(
                  label: 'Duplicate files',
                  value: '${insights.duplicateCount}',
                ),
                _InsightRow(
                  label: 'Largest videos',
                  value: '${insights.largestVideos.length} listed',
                ),
                _InsightRow(
                  label: 'Folders tracked',
                  value: '${insights.folderUsage.length}',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Suggested Cleanup',
            child: Column(
              children: suggestions
                  .map(
                    (CleanupSuggestion suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SuggestionTile(
                        suggestion: suggestion,
                        onStart: () => widget.onApplyMode(suggestion.mode),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.insights, required this.onOpenSwipe});

  final StorageInsights insights;
  final VoidCallback onOpenSwipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1F8A8A), Color(0xFF3567D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Swipe your gallery clean',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${insights.totalMediaCount} items indexed • ${formatBytes(insights.totalSizeBytes)} total',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F8A8A),
            ),
            onPressed: onOpenSwipe,
            child: const Text('Start Swipe Session'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
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
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onStart});

  final CleanupSuggestion suggestion;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF5F8FC),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1F8A8A).withValues(alpha: 0.12),
            child: Icon(suggestion.mode.icon, color: const Color(0xFF1F8A8A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  suggestion.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${suggestion.itemCount} items • ${formatBytes(suggestion.estimatedBytes)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                Text(
                  suggestion.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onStart, child: const Text('Start')),
        ],
      ),
    );
  }
}
