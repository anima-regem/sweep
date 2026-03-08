import 'package:intl/intl.dart';

String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final NumberFormat format = NumberFormat(unitIndex == 0 ? '0' : '0.0');
  return '${format.format(value)} ${units[unitIndex]}';
}

String formatDate(DateTime dateTime) {
  return DateFormat('dd MMM yyyy').format(dateTime);
}

String formatDurationSeconds(int? seconds) {
  if (seconds == null || seconds <= 0) {
    return '--:--';
  }

  final Duration duration = Duration(seconds: seconds);
  final int minutes = duration.inMinutes;
  final int remainingSeconds = duration.inSeconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}
