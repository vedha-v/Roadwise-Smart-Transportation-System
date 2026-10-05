import 'package:flutter/material.dart';

import 'theme.dart';
import '../screens/home/home_page.dart';
import '../screens/explore/explore_page.dart';
import '../screens/bookings/bookings_page.dart';
import '../screens/profile/profile_page.dart';

class RoadWiseApp extends StatefulWidget {
  const RoadWiseApp({super.key});

  @override
  State<RoadWiseApp> createState() => _RoadWiseAppState();
}

class _RoadWiseAppState extends State<RoadWiseApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadWise',
      theme: RoadWiseTheme.light(),
      darkTheme: RoadWiseTheme.dark(),
      themeMode: _themeMode,
      home: MainShell(
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
        onLogout: () {},
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onLogout;

  const MainShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1;

  List<Widget> get _pages => [
        const HomePage(),
        const ExplorePage(),
        const BookingsPage(),
        ProfilePage(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onLogout: widget.onLogout,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 76,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}