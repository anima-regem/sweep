import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SweepDestination { home, session, explore, trash, tags, profile }

extension SweepDestinationX on SweepDestination {
  String get label {
    switch (this) {
      case SweepDestination.home:
        return 'Home';
      case SweepDestination.session:
        return 'Session';
      case SweepDestination.explore:
        return 'Explore';
      case SweepDestination.trash:
        return 'Trash';
      case SweepDestination.tags:
        return 'Tags';
      case SweepDestination.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case SweepDestination.home:
        return CupertinoIcons.house;
      case SweepDestination.session:
        return CupertinoIcons.sparkles;
      case SweepDestination.explore:
        return CupertinoIcons.compass;
      case SweepDestination.trash:
        return CupertinoIcons.trash;
      case SweepDestination.tags:
        return CupertinoIcons.tag;
      case SweepDestination.profile:
        return CupertinoIcons.person;
    }
  }
}

final StateNotifierProvider<SweepShellController, SweepDestination>
sweepShellControllerProvider =
    StateNotifierProvider<SweepShellController, SweepDestination>(
      (Ref ref) => SweepShellController(),
    );

class SweepShellController extends StateNotifier<SweepDestination> {
  SweepShellController() : super(SweepDestination.session);

  void show(SweepDestination destination) {
    if (state == destination) {
      return;
    }
    state = destination;
  }

  void openSession() => show(SweepDestination.session);
}
