import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweep/models/sweep_models.dart';
import 'package:sweep/state/sweep_controller.dart';
import 'package:sweep/ui/screens/sweep_shell.dart';
import 'package:sweep/ui/screens/trash_tab.dart';
import 'package:sweep/ui/shell/shell_controller.dart';
import 'package:sweep/ui/widgets/swipe_deck.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('boots into the custom session shell in dark mode', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester);

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(SweepShell), findsOneWidget);
    expect(find.text('Session lane'), findsOneWidget);
    expect(find.byType(SwipeDeck, skipOffstage: false), findsOneWidget);
  });

  testWidgets('boots into the same shell in light mode', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester, brightness: Brightness.light);

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.text('Session lane'), findsOneWidget);
    expect(find.byType(SwipeDeck, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'dock navigation moves between destinations and back to session',
    (WidgetTester tester) async {
      await pumpSweepApp(tester, destination: SweepDestination.home);

      await tester.tap(find.byKey(const ValueKey<String>('dock-explore')));
      await settleSweep(tester);
      expect(find.text('Curate in bulk'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('dock-profile')));
      await settleSweep(tester);
      expect(find.text('Sweep metrics'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('dock-session')));
      await settleSweep(tester);
      expect(find.text('Session lane'), findsOneWidget);
    },
  );

  testWidgets('entering session hides top bar and keeps dock visible', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester, destination: SweepDestination.home);

    AnimatedOpacity topBar = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('shell-topbar-visibility')),
    );
    AnimatedOpacity dock = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('shell-dock-visibility')),
    );
    expect(topBar.opacity, 1);
    expect(dock.opacity, 1);

    await tester.tap(find.byKey(const ValueKey<String>('dock-session')));
    await settleSweep(tester);

    topBar = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('shell-topbar-visibility')),
    );
    dock = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('shell-dock-visibility')),
    );
    expect(topBar.opacity, 0);
    expect(dock.opacity, 1);
  });

  testWidgets('exit session returns to the last non-session destination', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester, destination: SweepDestination.home);

    await tester.tap(find.byKey(const ValueKey<String>('dock-explore')));
    await settleSweep(tester);
    expect(find.text('Curate in bulk'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('dock-session')));
    await settleSweep(tester);
    expect(find.text('Session lane'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('session-exit-button')));
    await settleSweep(tester);
    expect(find.text('Curate in bulk'), findsOneWidget);
  });

  testWidgets('review queue opens from session top strip and bottom rail', (
    WidgetTester tester,
  ) async {
    final SweepState seeded = buildSeededState(
      decisions: <String, SwipeDecision>{'camera_1': SwipeDecision.delete},
    );
    await pumpSweepApp(tester, seededState: seeded);

    await tester.tap(
      find.byKey(const ValueKey<String>('session-top-review-button')),
    );
    await settleSweep(tester);
    expect(find.text('Delete entire queue'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('dock-session')));
    await settleSweep(tester);
    await tester.tap(find.byKey(const ValueKey<String>('session-stat-trash')));
    await settleSweep(tester);
    expect(find.text('Delete entire queue'), findsOneWidget);
  });

  testWidgets(
    'tapping the session card opens and closes the custom action sheet',
    (WidgetTester tester) async {
      await pumpSweepApp(tester);

      final Finder deck = find.byType(SwipeDeck);
      final Rect deckRect = tester.getRect(deck);
      await tester.tapAt(deckRect.topLeft + const Offset(48, 48));
      await settleSweep(tester);
      expect(find.text('Tag+Move'), findsOneWidget);

      await tester.tap(find.text('Keep').last);
      await settleSweep(tester);
      expect(find.text('Tag+Move'), findsNothing);
    },
  );

  testWidgets('trash flow opens the custom confirmation dialog', (
    WidgetTester tester,
  ) async {
    final SweepState seeded = buildSeededState(
      decisions: <String, SwipeDecision>{'camera_1': SwipeDecision.delete},
    );

    await pumpScopedSweepWidget(tester, const TrashTab(), seededState: seeded);

    expect(find.text('Delete entire queue'), findsOneWidget);
    await tester.tap(find.text('Delete entire queue'));
    await settleSweep(tester);

    expect(find.text('Permanent delete'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleSweep(tester);
    expect(find.text('Permanent delete'), findsNothing);
  });

  testWidgets('session layout stays stable on compact phone height', (
    WidgetTester tester,
  ) async {
    await pumpSweepApp(tester, surfaceSize: const Size(360, 640));

    expect(
      find.byKey(const ValueKey<String>('session-top-strip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('session-bottom-rail')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
