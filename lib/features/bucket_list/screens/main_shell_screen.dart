import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../onboarding/tutorial_card.dart';
import '../../../../onboarding/tutorial_settings.dart';
import 'add_item_screen.dart';
import 'bucket_list_screen.dart';
import 'dashboard_screen.dart';
import 'spending_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _index = 0;

  void _openAddItem() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTutorial = !ref.watch(tutorialNotifierProvider);

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              BucketListScreen(),
              SpendingScreen(),
            ],
          ),
          floatingActionButton: _index == 0
              ? FloatingActionButton.extended(
                  onPressed: _openAddItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() {
                _index = value;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Bucket List',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Spending',
              ),
            ],
          ),
        ),
        if (showTutorial)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                child: TutorialCard(
                  onDismiss: () {
                    ref.read(tutorialNotifierProvider.notifier).complete();
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}