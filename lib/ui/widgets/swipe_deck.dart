import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../models/sweep_models.dart';
import 'media_preview.dart';

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    required this.current,
    required this.next,
    required this.onSwipe,
    required this.onTap,
    super.key,
  });

  final MediaItem? current;
  final MediaItem? next;
  final void Function(MediaItem item, SwipeDirection direction) onSwipe;
  final VoidCallback onTap;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isExiting = false;

  @override
  Widget build(BuildContext context) {
    if (widget.current == null) {
      return const SizedBox.shrink();
    }

    final SweepThemeData theme = SweepTheme.of(context);
    final double dragDistance = _dragOffset.distance;
    final double tiltDegrees = (_dragOffset.dx / 24).clamp(-7.0, 7.0);
    final SwipeDirection? direction = _directionFromOffset(_dragOffset);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final MediaItem current = widget.current!;
        final double depth = min(1.0, dragDistance / 120);

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (widget.next != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, 24 - depth * 12),
                  child: Transform.scale(
                    scale: 0.90 + depth * 0.06,
                    child: Opacity(
                      opacity: 0.42 + depth * 0.26,
                      child: _CardShell(
                        child: MediaPreview(
                          item: widget.next!,
                          borderRadius: BorderRadius.circular(
                            theme.radii.lg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: _isDragging
                  ? Duration.zero
                  : theme.motion.component,
              curve: theme.motion.emphasized,
              transform: Matrix4.identity()
                ..translateByDouble(_dragOffset.dx, _dragOffset.dy, 0, 1)
                ..rotateZ(tiltDegrees * pi / 180),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.radii.lg),
                boxShadow: <BoxShadow>[
                  ...theme.elevation.panel(1.1),
                  ...theme.elevation.glow(
                    _glowColor(theme, direction),
                    min(0.95, dragDistance / 180),
                  ),
                ],
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onPanStart: (_) {
                  if (_isExiting) {
                    return;
                  }
                  setState(() {
                    _isDragging = true;
                  });
                },
                onPanUpdate: (DragUpdateDetails details) {
                  if (_isExiting) {
                    return;
                  }
                  setState(() {
                    _dragOffset += details.delta;
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  final SwipeDirection? swiped = _resolveSwipe(
                    offset: _dragOffset,
                    velocity: details.velocity.pixelsPerSecond,
                  );

                  if (swiped != null) {
                    final Offset exitOffset = _exitOffsetFor(
                      swiped,
                      constraints.biggest,
                    );
                    setState(() {
                      _isDragging = false;
                      _isExiting = true;
                      _dragOffset = exitOffset;
                    });
                    Future<void>.delayed(theme.motion.component, () {
                      if (!mounted) {
                        return;
                      }
                      widget.onSwipe(current, swiped);
                      setState(() {
                        _dragOffset = Offset.zero;
                        _isExiting = false;
                      });
                    });
                    return;
                  }

                  setState(() {
                    _isDragging = false;
                    _dragOffset = Offset.zero;
                  });
                },
                child: _CardShell(
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: MediaPreview(
                          item: current,
                          borderRadius: BorderRadius.circular(theme.radii.lg),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _SwipeOverlay(
                            direction: direction,
                            intensity: min(1.0, dragDistance / 110),
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
      },
    );
  }

  Offset _exitOffsetFor(SwipeDirection direction, Size size) {
    switch (direction) {
      case SwipeDirection.left:
        return Offset(-size.width * 1.2, 28);
      case SwipeDirection.right:
        return Offset(size.width * 1.2, -18);
      case SwipeDirection.up:
        return Offset(0, -size.height * 1.1);
      case SwipeDirection.down:
        return Offset(0, size.height * 1.0);
    }
  }

  SwipeDirection? _resolveSwipe({
    required Offset offset,
    required Offset velocity,
  }) {
    const double distanceThreshold = 112;
    const double velocityThreshold = 940;

    if (offset.distance < distanceThreshold &&
        velocity.distance < velocityThreshold) {
      return null;
    }

    final double horizontalBias = offset.dx.abs() + velocity.dx.abs() * 0.08;
    final double verticalBias = offset.dy.abs() + velocity.dy.abs() * 0.08;

    if (horizontalBias >= verticalBias) {
      return offset.dx + velocity.dx > 0
          ? SwipeDirection.right
          : SwipeDirection.left;
    }

    return offset.dy + velocity.dy > 0
        ? SwipeDirection.down
        : SwipeDirection.up;
  }

  SwipeDirection? _directionFromOffset(Offset offset) {
    if (offset.distance < 18) {
      return null;
    }

    if (offset.dx.abs() >= offset.dy.abs()) {
      return offset.dx >= 0 ? SwipeDirection.right : SwipeDirection.left;
    }

    return offset.dy >= 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  Color _glowColor(SweepThemeData theme, SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.left:
        return theme.colors.danger;
      case SwipeDirection.right:
        return theme.colors.success;
      case SwipeDirection.up:
        return theme.colors.info;
      case SwipeDirection.down:
        return theme.colors.warning;
      case null:
        return const Color(0x00000000);
    }
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF03070D),
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(
          color: theme.colors.border.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(aspectRatio: 0.68, child: child),
    );
  }
}

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({required this.direction, required this.intensity});

  final SwipeDirection? direction;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    if (direction == null) {
      return const SizedBox.shrink();
    }

    final SweepThemeData theme = SweepTheme.of(context);
    late final Color color;
    late final IconData icon;
    late final String text;

    switch (direction!) {
      case SwipeDirection.left:
        color = theme.colors.danger;
        icon = CupertinoIcons.trash;
        text = 'DELETE';
        break;
      case SwipeDirection.right:
        color = theme.colors.success;
        icon = CupertinoIcons.heart;
        text = 'KEEP';
        break;
      case SwipeDirection.up:
        color = theme.colors.info;
        icon = CupertinoIcons.tag;
        text = 'TAG / MOVE';
        break;
      case SwipeDirection.down:
        color = theme.colors.warning;
        icon = CupertinoIcons.forward;
        text = 'SKIP';
        break;
    }

    return AnimatedOpacity(
      duration: theme.motion.component,
      opacity: intensity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.radii.lg),
          border: Border.all(color: color.withValues(alpha: 0.84), width: 2.4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              color.withValues(alpha: 0.22 * intensity),
              const Color(0x00000000),
              color.withValues(alpha: 0.08 * intensity),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Transform.scale(
              scale: 0.9 + intensity * 0.1,
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(theme.radii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, color: theme.colors.textOnAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: theme.typography.label.copyWith(
                        color: theme.colors.textOnAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
