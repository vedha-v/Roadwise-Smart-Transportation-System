import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          // Profile heading
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          // Appearance section
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text(
                    'Appearance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Customize how RoadWise looks'),
                ),

                const Divider(height: 1),

                SwitchListTile(
                  secondary: Icon(
                    isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    isDarkMode
                        ? 'Dark mode is enabled'
                        : 'Use light mode',
                  ),
                  value: isDarkMode,
                  onChanged: onDarkModeChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}