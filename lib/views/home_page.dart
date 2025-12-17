import 'package:flutter/material.dart';

import 'checkpoint_tab_view.dart';
import 'my_second_link_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isPageView = true;

  void _toggleViewMode() {
    setState(() {
      _isPageView = !_isPageView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CheckpointTabView(
            tabType: TabType.woodlands,
            isPageView: _isPageView,
            onToggleViewMode: _toggleViewMode,
          ),
          CheckpointTabView(
            tabType: TabType.tuas,
            isPageView: _isPageView,
            onToggleViewMode: _toggleViewMode,
          ),
          MySecondLinkPage(
            isPageView: _isPageView,
            onToggleViewMode: _toggleViewMode,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forest_outlined),
            selectedIcon: Icon(Icons.forest),
            label: 'Woodlands',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Tuas',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_road_outlined),
            selectedIcon: Icon(Icons.add_road),
            label: 'MY 2nd Link',
          ),
        ],
      ),
    );
  }
}
