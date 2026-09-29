import 'package:flutter/material.dart';

import 'theme.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_page.dart';
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
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoggedIn = false;

  void _changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    AuthService.logout();

    setState(() {
      _isLoggedIn = false;
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
      home: _isLoggedIn
          ? MainShell(
              themeMode: _themeMode,
              onThemeModeChanged: _changeThemeMode,
              onLogout: _handleLogout,
            )
          : LoginPage(
              onLoggedIn: _handleLogin,
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
  int _currentIndex = 0;

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 86,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFDCEBE3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: Color(0xFF17201B),
            ),
            selectedIcon: Icon(
              Icons.home,
              color: Color(0xFF17201B),
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
              color: Color(0xFF17201B),
            ),
            selectedIcon: Icon(
              Icons.explore,
              color: Color(0xFF17201B),
            ),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.confirmation_number_outlined,
              color: Color(0xFF17201B),
            ),
            selectedIcon: Icon(
              Icons.confirmation_number,
              color: Color(0xFF17201B),
            ),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: Color(0xFF17201B),
            ),
            selectedIcon: Icon(
              Icons.person,
              color: Color(0xFF17201B),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}