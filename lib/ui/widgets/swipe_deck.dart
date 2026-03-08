import 'dart:math';

import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.current == null) {
      return const SizedBox.shrink();
    }

    final double dragDistance = _dragOffset.distance;
    final double tiltDegrees = (_dragOffset.dx / 24).clamp(-7.0, 7.0);
    final SwipeDirection? direction = _directionFromOffset(_dragOffset);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final MediaItem current = widget.current!;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (widget.next != null)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.94,
                  child: Transform.translate(
                    offset: const Offset(0, 16),
                    child: Opacity(
                      opacity: 0.72,
                      child: _CardShell(
                        child: MediaPreview(
                          item: widget.next!,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _glowColor(
                      direction,
                    ).withValues(alpha: min(0.48, dragDistance / 220)),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: widget.onTap,
                onPanUpdate: (DragUpdateDetails details) {
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
                    widget.onSwipe(current, swiped);
                  }

                  setState(() {
                    _dragOffset = Offset.zero;
                  });
                },
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform.rotate(
                    angle: tiltDegrees * pi / 180,
                    child: _CardShell(
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: MediaPreview(
                              item: current,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _SwipeOverlay(
                                direction: direction,
                                intensity: min(1.0, dragDistance / 120),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  SwipeDirection? _resolveSwipe({
    required Offset offset,
    required Offset velocity,
  }) {
    const double distanceThreshold = 108;
    const double velocityThreshold = 900;

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
    if (offset.distance < 20) {
      return null;
    }

    if (offset.dx.abs() >= offset.dy.abs()) {
      return offset.dx >= 0 ? SwipeDirection.right : SwipeDirection.left;
    }

    return offset.dy >= 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  Color _glowColor(SwipeDirection? direction) {
    switch (direction) {
      case SwipeDirection.left:
        return const Color(0xFFF25F5C);
      case SwipeDirection.right:
        return const Color(0xFF45C08A);
      case SwipeDirection.up:
        return const Color(0xFF4C77E2);
      case SwipeDirection.down:
        return const Color(0xFFFAB84C);
      case null:
        return Colors.transparent;
    }
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
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

    late final Color color;
    late final IconData icon;
    late final String text;

    switch (direction!) {
      case SwipeDirection.left:
        color = const Color(0xFFF25F5C);
        icon = Icons.delete_outline;
        text = 'DELETE';
        break;
      case SwipeDirection.right:
        color = const Color(0xFF45C08A);
        icon = Icons.favorite_outline;
        text = 'KEEP';
        break;
      case SwipeDirection.up:
        color = const Color(0xFF4C77E2);
        icon = Icons.sell_outlined;
        text = 'TAG / ORGANIZE';
        break;
      case SwipeDirection.down:
        color = const Color(0xFFFAB84C);
        icon = Icons.skip_next_outlined;
        text = 'SKIP';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.8), width: 3),
        borderRadius: BorderRadius.circular(24),
        color: color.withValues(alpha: 0.16 * intensity),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
