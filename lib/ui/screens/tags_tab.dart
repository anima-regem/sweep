import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';

class TagsTab extends ConsumerStatefulWidget {
  const TagsTab({super.key});

  @override
  ConsumerState<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends ConsumerState<TagsTab> {
  final TextEditingController _tagController = TextEditingController();
  final Set<String> _expanded = <String>{};

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final SweepState state = ref.watch(sweepControllerProvider);
    final Map<String, List<MediaItem>> collections = state.taggedCollections;

    return SweepPage(
      eyebrow: 'Collections',
      title: 'Tag and retrieve',
      subtitle:
          'Create lightweight labels, keep people or themes grouped, and browse collections without leaving Sweep.',
      children: <Widget>[
        SweepReveal(
          child: SweepSurface(
            tone: SweepSurfaceTone.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SweepSectionHeader(
                  title: 'Create a tag',
                  subtitle: 'Simple labels are enough to make the archive feel organized.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SweepTextField(
                        label: 'Label',
                        placeholder: 'Friends / Work / Travel',
                        controller: _tagController,
                        prefix: const Icon(CupertinoIcons.tag),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: SweepButton(
                        label: 'Create',
                        onPressed: () {
                          final String tag = _tagController.text.trim();
                          if (tag.isEmpty) {
                            return;
                          }
                          controller.addCustomTag(tag);
                          _tagController.clear();
                        },
                      ),
                    ),
                  ],
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
                          color: theme.colors.primary,
                          filled: true,
                        ),
                      )
                      .toList(),
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
              children: const <Widget>[
                SweepSectionHeader(
                  title: 'People labels',
                  subtitle:
                      'Auto face clustering stays out of v1, but manual labels keep the same retrieval flow alive.',
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    SweepPill(
                      text: 'Arjun',
                      icon: CupertinoIcons.person_crop_circle_fill,
                      filled: true,
                    ),
                    SweepPill(
                      text: 'Maya',
                      icon: CupertinoIcons.person_crop_circle_fill,
                      filled: true,
                    ),
                    SweepPill(
                      text: 'Dad',
                      icon: CupertinoIcons.person_crop_circle_fill,
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (collections.isEmpty)
          const SweepReveal(
            delay: Duration(milliseconds: 120),
            child: SweepEmptyState(
              icon: CupertinoIcons.tag,
              title: 'No tagged media yet',
              body: 'Swipe up in Session or use bulk actions in Explore to start labeling media.',
            ),
          )
        else
          SweepReveal(
            delay: const Duration(milliseconds: 120),
            child: Column(
              children: collections.entries.map((
                MapEntry<String, List<MediaItem>> entry,
              ) {
                final bool expanded = _expanded.contains(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expanded.remove(entry.key);
                        } else {
                          _expanded.add(entry.key);
                        }
                      });
                    },
                    child: SweepSurface(
                      tone: SweepSurfaceTone.raised,
                      child: AnimatedSize(
                        duration: theme.motion.component,
                        curve: theme.motion.standard,
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      theme.radii.md,
                                    ),
                                    gradient: theme.heroGradient,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.tag_fill,
                                    color: theme.colors.textOnAccent,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        entry.key,
                                        style: theme.typography.bodyStrong,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${entry.value.length} media items',
                                        style: theme.typography.detail,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  expanded
                                      ? CupertinoIcons.chevron_up
                                      : CupertinoIcons.chevron_down,
                                  size: 18,
                                  color: theme.colors.textSecondary,
                                ),
                              ],
                            ),
                            if (expanded) ...<Widget>[
                              const SizedBox(height: 14),
                              ...entry.value.take(15).map(
                                (MediaItem item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SweepListRow(
                                    title:
                                        '${item.resolvedFolder} • ${formatMaybeBytes(item.sizeBytes)}',
                                    subtitle: formatDate(item.createdAt),
                                    leading: Icon(item.kind.icon),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
