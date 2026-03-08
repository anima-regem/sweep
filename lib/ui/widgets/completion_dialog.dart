import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({
    required this.processed,
    required this.freedBytes,
    super.key,
  });

  final int processed;
  final int freedBytes;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 120, child: _ConfettiBurst()),
            const SizedBox(height: 8),
            const Text(
              'Session Complete',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'You cleaned ${formatBytes(freedBytes)} today.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '$processed items processed in this swipe run.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst();

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    final Random random = Random(11);
    _particles = List<_Particle>.generate(28, (int index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3,
        vx: random.nextDouble() * 2 - 1,
        vy: random.nextDouble() * 1.8 + 0.6,
        size: random.nextDouble() * 8 + 5,
        color: Color.lerp(
          const Color(0xFF1F8A8A),
          const Color(0xFFA5C957),
          random.nextDouble(),
        )!,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: Curves.easeOut.transform(_controller.value),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final _Particle particle in particles) {
      final Offset center = Offset(
        size.width * particle.x + particle.vx * 70 * progress,
        size.height * particle.y + particle.vy * 90 * progress,
      );
      paint.color = particle.color.withValues(
        alpha: (1 - progress).clamp(0.0, 1.0),
      );
      canvas.drawCircle(center, particle.size * (1 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
}
