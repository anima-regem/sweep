import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';

class TagsTab extends ConsumerStatefulWidget {
  const TagsTab({super.key});

  @override
  ConsumerState<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends ConsumerState<TagsTab> {
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final SweepState state = ref.watch(sweepControllerProvider);
    final Map<String, List<MediaItem>> collections = controller
        .taggedCollections();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tagging System',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Create and organize media with lightweight tags.'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'Friends / Work / Travel',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final String tag = _tagController.text.trim();
                        if (tag.isEmpty) {
                          return;
                        }
                        controller.addCustomTag(tag);
                        _tagController.clear();
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.customTags
                      .map(
                        (String tag) => Chip(
                          avatar: const Icon(Icons.sell_outlined, size: 16),
                          label: Text(tag),
                        ),
                      )
                      .toList(),
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
                  'Face Tagging (Phase 2)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manual people labels are supported via tags now. '
                  'Auto face clustering is planned for a future release.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: const <Widget>[
                    Chip(label: Text('Arjun')),
                    Chip(label: Text('Maya')),
                    Chip(label: Text('Dad')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (collections.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Center(
              child: Text('No tagged media yet. Swipe up to tag items.'),
            ),
          )
        else
          ...collections.entries.map(
            (MapEntry<String, List<MediaItem>> entry) => Card(
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${entry.value.length} media items'),
                children: entry.value.take(15).map((MediaItem item) {
                  return ListTile(
                    dense: true,
                    leading: Icon(item.kind.icon),
                    title: Text(
                      '${item.resolvedFolder} • ${formatBytes(item.sizeBytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(formatDate(item.createdAt)),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
