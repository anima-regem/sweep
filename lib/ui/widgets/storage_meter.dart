import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../utils/formatters.dart';
import '../components/sweep_primitives.dart';

class StorageMeter extends StatelessWidget {
  const StorageMeter({
    required this.totalBytes,
    required this.reclaimableBytes,
    super.key,
  });

  final int totalBytes;
  final int reclaimableBytes;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final double ratio = totalBytes == 0
        ? 0
        : (reclaimableBytes / totalBytes).clamp(0.0, 1.0);

    return SweepSurface(
      gradient: theme.heroGradient,
      borderRadius: BorderRadius.circular(theme.radii.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Storage meter',
            style: theme.typography.title.copyWith(
              color: theme.colors.textOnAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatBytes(reclaimableBytes)} reclaimable right now',
            style: theme.typography.detail.copyWith(
              color: theme.colors.textOnAccent.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 16),
          SweepProgressBar(
            value: ratio,
            color: theme.colors.textOnAccent.withValues(alpha: 0.95),
            height: 12,
          ),
          const SizedBox(height: 10),
          Text(
            'Total indexed: ${formatBytes(totalBytes)}',
            style: theme.typography.caption.copyWith(
              color: theme.colors.textOnAccent.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
