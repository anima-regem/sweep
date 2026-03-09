import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweep/app/theme.dart';
import 'package:sweep/models/sweep_models.dart';
import 'package:sweep/ui/widgets/swipe_deck.dart';

import 'test_helpers.dart';

Future<void> _pumpDeck(
  WidgetTester tester, {
  required void Function(SwipeDirection direction) onSwipe,
}) async {
  final List<MediaItem> media = buildFixedMedia();

  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder:
          <T>(RouteSettings settings, WidgetBuilder builder) =>
              PageRouteBuilder<T>(
                settings: settings,
                pageBuilder:
                    (
                      BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) => builder(context),
              ),
      home: SweepThemeHost(
        child: Center(
          child: SizedBox(
            width: 320,
            child: SwipeDeck(
              current: media.first,
              next: media[1],
              onTap: () {},
              onSwipe: (MediaItem item, SwipeDirection direction) {
                onSwipe(direction);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('dragging left reports a delete swipe', (
    WidgetTester tester,
  ) async {
    SwipeDirection? result;
    await _pumpDeck(tester, onSwipe: (SwipeDirection direction) => result = direction);

    final Offset center = tester.getRect(find.byType(SwipeDeck)).center;
    await tester.dragFrom(center, const Offset(-520, 0));
    await tester.pump(const Duration(milliseconds: 420));

    expect(result, SwipeDirection.left);
  });

  testWidgets('dragging right reports a keep swipe', (WidgetTester tester) async {
    SwipeDirection? result;
    await _pumpDeck(tester, onSwipe: (SwipeDirection direction) => result = direction);

    final Offset center = tester.getRect(find.byType(SwipeDeck)).center;
    await tester.dragFrom(center, const Offset(520, 0));
    await tester.pump(const Duration(milliseconds: 420));

    expect(result, SwipeDirection.right);
  });

  testWidgets('dragging up reports a tag swipe', (WidgetTester tester) async {
    SwipeDirection? result;
    await _pumpDeck(tester, onSwipe: (SwipeDirection direction) => result = direction);

    final Offset center = tester.getRect(find.byType(SwipeDeck)).center;
    await tester.dragFrom(center, const Offset(0, -520));
    await tester.pump(const Duration(milliseconds: 420));

    expect(result, SwipeDirection.up);
  });

  testWidgets('dragging down reports a skip swipe', (WidgetTester tester) async {
    SwipeDirection? result;
    await _pumpDeck(tester, onSwipe: (SwipeDirection direction) => result = direction);

    final Offset center = tester.getRect(find.byType(SwipeDeck)).center;
    await tester.dragFrom(center, const Offset(0, 520));
    await tester.pump(const Duration(milliseconds: 420));

    expect(result, SwipeDirection.down);
  });
}
