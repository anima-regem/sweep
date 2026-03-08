import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

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
    final double ratio = totalBytes == 0
        ? 0
        : (reclaimableBytes / totalBytes).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1F8A8A), Color(0xFFA5C957)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Storage Meter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatBytes(reclaimableBytes)} can be cleaned',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.white24,
              height: 14,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween<double>(begin: 0, end: ratio),
                builder: (BuildContext context, double value, Widget? child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total indexed: ${formatBytes(totalBytes)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
