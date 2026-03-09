import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import '../components/sweep_primitives.dart';
import '../shell/shell_controller.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'swipe_tab.dart';
import 'tags_tab.dart';
import 'trash_tab.dart';

class SweepShell extends ConsumerWidget {
  const SweepShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SweepThemeData theme = SweepTheme.of(context);
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );
    final SweepDestination destination = ref.watch(sweepShellControllerProvider);
    final SweepShellController shell = ref.read(
      sweepShellControllerProvider.notifier,
    );

    final List<Widget> pages = <Widget>[
      HomeTab(
        onOpenSwipe: shell.openSession,
        onApplyMode: (DiscoveryMode mode, {String? folder}) {
          controller.setDiscoveryMode(mode, folderName: folder);
          shell.openSession();
        },
      ),
      SwipeTab(onOpenTrash: () => shell.show(SweepDestination.trash)),
      ExploreTab(
        onApplyMode: (DiscoveryMode mode, {String? folder}) {
          controller.setDiscoveryMode(mode, folderName: folder);
          shell.openSession();
        },
      ),
      const TrashTab(),
      const TagsTab(),
      const ProfileTab(),
    ];

    final int pageIndex = switch (destination) {
      SweepDestination.home => 0,
      SweepDestination.session => 1,
      SweepDestination.explore => 2,
      SweepDestination.trash => 3,
      SweepDestination.tags => 4,
      SweepDestination.profile => 5,
    };

    final SystemUiOverlayStyle overlayStyle =
        theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: ColoredBox(
        color: theme.colors.background,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: theme.appGradient),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _SweepAtmosphere()),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 76),
                  child: IndexedStack(index: pageIndex, children: pages),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      theme.spacing.gutter,
                      10,
                      theme.spacing.gutter,
                      0,
                    ),
                    child: _ShellTopBar(
                      destination: destination,
                      isLoading: state.isLoading,
                      statusMessage: state.statusMessage,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: theme.spacing.dockInset,
                right: theme.spacing.dockInset,
                bottom: theme.spacing.dockInset,
                child: SafeArea(
                  top: false,
                  child: _ShellDock(
                    destination: destination,
                    onSelect: shell.show,
                    onOpenSession: shell.openSession,
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

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({
    required this.destination,
    required this.isLoading,
    required this.statusMessage,
  });

  final SweepDestination destination;
  final bool isLoading;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Row(
      children: <Widget>[
        SweepSurface(
          tone: SweepSurfaceTone.raised,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: theme.heroGradient,
                  borderRadius: BorderRadius.circular(theme.radii.sm),
                ),
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 16,
                  color: theme.colors.textOnAccent,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('SWEEP', style: theme.typography.caption),
                  Text(
                    destination.label,
                    style: theme.typography.label.copyWith(
                      color: theme.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SweepSurface(
              tone: isLoading
                  ? SweepSurfaceTone.accent
                  : SweepSurfaceTone.raised,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (isLoading) ...<Widget>[
                    CupertinoActivityIndicator(
                      color: theme.colors.primary,
                      radius: 8,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      statusMessage ?? 'Gallery ready',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.detail.copyWith(
                        color: isLoading
                            ? theme.colors.primary
                            : theme.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShellDock extends StatelessWidget {
  const _ShellDock({
    required this.destination,
    required this.onSelect,
    required this.onOpenSession,
  });

  final SweepDestination destination;
  final ValueChanged<SweepDestination> onSelect;
  final VoidCallback onOpenSession;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    const List<SweepDestination> dockDestinations = <SweepDestination>[
      SweepDestination.home,
      SweepDestination.explore,
      SweepDestination.trash,
      SweepDestination.tags,
      SweepDestination.profile,
    ];
    final bool sessionSelected = destination == SweepDestination.session;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        SweepSurface(
          tone: SweepSurfaceTone.raised,
          borderRadius: BorderRadius.circular(theme.radii.lg),
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 14),
          child: Row(
            children: dockDestinations.map((SweepDestination item) {
              final bool selected = item == destination;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(item),
                  child: AnimatedContainer(
                    duration: theme.motion.component,
                    curve: theme.motion.standard,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colors.primarySoft
                          : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(theme.radii.md),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: 20,
                          color: selected
                              ? theme.colors.primary
                              : theme.colors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: theme.typography.caption.copyWith(
                            color: selected
                                ? theme.colors.primary
                                : theme.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Positioned(
          top: -30,
          child: GestureDetector(
            onTap: onOpenSession,
            child: AnimatedContainer(
              duration: theme.motion.component,
              curve: theme.motion.standard,
              width: sessionSelected ? 88 : 78,
              height: sessionSelected ? 88 : 78,
              decoration: BoxDecoration(
                gradient: theme.heroGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colors.textOnAccent.withValues(alpha: 0.22),
                ),
                boxShadow: theme.elevation.glow(theme.colors.heroStart, 0.9),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    SweepDestination.session.icon,
                    color: theme.colors.textOnAccent,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Session',
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.textOnAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SweepAtmosphere extends StatefulWidget {
  const _SweepAtmosphere();

  @override
  State<_SweepAtmosphere> createState() => _SweepAtmosphereState();
}

class _SweepAtmosphereState extends State<_SweepAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SweepTheme.of(context).motion.reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return Stack(
          children: <Widget>[
            _Orb(
              color: theme.colors.orbOne,
              alignment: Alignment(-0.9 + t * 0.45, -0.95 + t * 0.22),
              size: 280,
            ),
            _Orb(
              color: theme.colors.orbTwo,
              alignment: Alignment(0.88 - t * 0.36, -0.25),
              size: 240,
            ),
            _Orb(
              color: theme.colors.orbThree,
              alignment: Alignment(0.15, 0.92 - t * 0.55),
              size: 260,
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.alignment,
    required this.size,
  });

  final Color color;
  final Alignment alignment;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: math.pi / 12,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  color.withValues(alpha: 0.40),
                  color.withValues(alpha: 0.03),
                  const Color(0x00000000),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
