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
  bool _isDarkMode = false;

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadWise',

      // Light and dark themes
      theme: RoadWiseTheme.light(),
      darkTheme: RoadWiseTheme.dark(),

      // Switch between light and dark mode
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: MainShell(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _toggleDarkMode,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const MainShell({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const HomePage(),
        const ExplorePage(),
        const BookingsPage(),
        ProfilePage(
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

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