import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweep/models/sweep_models.dart';
import 'package:sweep/state/sweep_controller.dart';
import 'package:sweep/ui/screens/sweep_shell.dart';
import 'package:sweep/ui/screens/trash_tab.dart';
import 'package:sweep/ui/widgets/swipe_deck.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('boots into the custom session shell in dark mode', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester);

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(SweepShell), findsOneWidget);
    expect(find.text('Live swipe lane'), findsOneWidget);
    expect(find.byType(SwipeDeck, skipOffstage: false), findsOneWidget);
  });

  testWidgets('boots into the same shell in light mode', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester, brightness: Brightness.light);

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.text('Live swipe lane'), findsOneWidget);
    expect(find.text('SWEEP'), findsOneWidget);
  });

  testWidgets('dock navigation moves between destinations and back to session', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester);

    await tester.tap(find.text('Explore').last);
    await settleSweep(tester);
    expect(find.text('Curate in bulk'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await settleSweep(tester);
    expect(find.text('Sweep metrics'), findsOneWidget);

    await tester.tap(find.text('Session').last);
    await settleSweep(tester);
    expect(find.text('Live swipe lane'), findsOneWidget);
  });

  testWidgets('tapping the session card opens and closes the custom action sheet', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester);

    final Finder deck = find.byType(SwipeDeck);
    final Rect deckRect = tester.getRect(deck);
    await tester.tapAt(deckRect.topLeft + const Offset(48, 48));
    await settleSweep(tester);
    expect(find.text('Tag / move'), findsOneWidget);

    await tester.tap(find.text('Keep').last);
    await settleSweep(tester);
    expect(find.text('Tag / move'), findsNothing);
  });

  testWidgets('trash flow opens the custom confirmation dialog', (
    WidgetTester tester,
  ) async {
    final SweepState seeded = buildSeededState(
      decisions: <String, SwipeDecision>{'camera_1': SwipeDecision.delete},
    );

    await pumpScopedSweepWidget(
      tester,
      const TrashTab(),
      seededState: seeded,
    );

    expect(find.text('Delete entire queue'), findsOneWidget);
    await tester.tap(find.text('Delete entire queue'));
    await settleSweep(tester);

    expect(find.text('Permanent delete'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleSweep(tester);
    expect(find.text('Permanent delete'), findsNothing);
  });
}
