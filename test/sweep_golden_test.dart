import 'package:flutter/material.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';

import 'package:sweep/models/sweep_models.dart';
import 'package:sweep/state/sweep_controller.dart';
import 'package:sweep/ui/screens/sweep_shell.dart';
import 'package:sweep/ui/shell/shell_controller.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('shell session dark golden', (WidgetTester tester) async {
    await pumpSweepApp(tester);

    await expectLater(
      find.byType(SweepShell),
      matchesGoldenFile('goldens/sweep_shell_dark.png'),
    );
  });

  testWidgets('session light golden', (WidgetTester tester) async {
    await pumpSweepApp(tester, brightness: Brightness.light);

    await expectLater(
      find.byType(SweepShell),
      matchesGoldenFile('goldens/sweep_session_light.png'),
    );
  });

  testWidgets('explore selection golden', (WidgetTester tester) async {
    final SweepState seeded = buildSeededState(
      discoveryMode: DiscoveryMode.screenshots,
      selectedBulkIds: <String>{'screenshot_1'},
    );

    await pumpSweepApp(
      tester,
      destination: SweepDestination.explore,
      seededState: seeded,
    );

    await expectLater(
      find.byType(SweepShell),
      matchesGoldenFile('goldens/sweep_explore_dark.png'),
    );
  });

  testWidgets('trash queue golden', (WidgetTester tester) async {
    final SweepState seeded = buildSeededState(
      decisions: <String, SwipeDecision>{
        'camera_1': SwipeDecision.delete,
        'video_1': SwipeDecision.delete,
      },
    );

    await pumpSweepApp(
      tester,
      destination: SweepDestination.trash,
      seededState: seeded,
    );

    await expectLater(
      find.byType(SweepShell),
      matchesGoldenFile('goldens/sweep_trash_dark.png'),
    );
  });
}
