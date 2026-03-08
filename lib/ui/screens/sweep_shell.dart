import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sweep_models.dart';
import '../../state/sweep_controller.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'swipe_tab.dart';
import 'tags_tab.dart';
import 'trash_tab.dart';

class SweepShell extends ConsumerStatefulWidget {
  const SweepShell({super.key});

  @override
  ConsumerState<SweepShell> createState() => _SweepShellState();
}

class _SweepShellState extends ConsumerState<SweepShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final SweepState state = ref.watch(sweepControllerProvider);
    final SweepController controller = ref.read(
      sweepControllerProvider.notifier,
    );

    final List<Widget> tabs = <Widget>[
      HomeTab(
        onOpenSwipe: () => _setTab(1),
        onApplyMode: (DiscoveryMode mode, {String? folder}) {
          controller.setDiscoveryMode(mode, folderName: folder);
          _setTab(1);
        },
      ),
      SwipeTab(onOpenTrash: () => _setTab(2)),
      const TrashTab(),
      ExploreTab(
        onApplyMode: (DiscoveryMode mode, {String? folder}) {
          controller.setDiscoveryMode(mode, folderName: folder);
          _setTab(1);
        },
      ),
      const TagsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Sweep'),
        centerTitle: false,
        actions: <Widget>[
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF3F6FA),
              Color(0xFFEAF3EE),
              Color(0xFFFFF7EE),
            ],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: tabs),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _setTab,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swipe_outlined),
              label: 'Swipe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delete_outline),
              label: 'Trash',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sell_outlined),
              label: 'Tags',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _setTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }
}
