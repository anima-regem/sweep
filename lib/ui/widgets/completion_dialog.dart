import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';

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
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepDialogFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 132, child: _ConfettiBurst()),
          const SizedBox(height: 4),
          Text('Session complete', style: theme.typography.display),
          const SizedBox(height: 10),
          Text(
            'You cleaned ${formatBytes(freedBytes)} in this run.',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 6),
          Text(
            '$processed items processed before the queue ran dry.',
            style: theme.typography.detail,
          ),
          const SizedBox(height: 18),
          SweepButton(
            label: 'Keep going',
            icon: CupertinoIcons.arrow_right,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
      duration: const Duration(milliseconds: 1280),
    )..forward();

    final Random random = Random(11);
    _particles = List<_Particle>.generate(30, (int index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.32,
        vx: random.nextDouble() * 2 - 1,
        vy: random.nextDouble() * 1.8 + 0.7,
        size: random.nextDouble() * 7 + 5,
        color: Color.lerp(
          const Color(0xFF7CF6D4),
          const Color(0xFF6F7DF6),
          random.nextDouble(),
        )!,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SweepTheme.of(context).motion.reduceMotion) {
      _controller.value = 1;
      _controller.stop();
    }
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
        size.width * particle.x + particle.vx * 78 * progress,
        size.height * particle.y + particle.vy * 92 * progress,
      );
      paint.color = particle.color.withValues(
        alpha: (1 - progress).clamp(0.0, 1.0),
      );
      canvas.drawCircle(center, particle.size * (1 - progress * 0.28), paint);
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
