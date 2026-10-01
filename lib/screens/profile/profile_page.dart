import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ProfilePage({
    super.key,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Local profile data for now.
  // We are intentionally keeping this pre-auth to avoid blocking exploration.
  String _name = 'RoadWise user';
  String _email = 'user@roadwise.com';
  String _phone = '+91 00000 00000';

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String get _appearance {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  final List<String> _savedPlaces = [
    'Home',
    'College',
  ];

  final List<String> _recentActivity = [
    'Parking reservation',
    'Searched for nearby parking',
    'Viewed City Centre Parking',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your RoadWise experience.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProfileAvatar(
                    size: 64,
                    color: colors.primary,
                    background: colors.primary.withValues(alpha: 0.12),
                  ),
                ],
              ),

              const SizedBox(height: 34),

              // ============================================================
              // PROFILE SUMMARY
              // ============================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _ProfileAvatar(
                      size: 54,
                      color: colors.primary,
                      background: colors.primary.withValues(alpha: 0.13),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              // ============================================================
              // ACCOUNT
              // ============================================================

              const _SectionTitle(title: 'Account'),

              const SizedBox(height: 8),

              _ProfileRow(
                icon: Icons.person_outline_rounded,
                title: 'Personal information',
                subtitle: 'Manage your account details',
                onTap: _showPersonalInformation,
              ),

              const _ProfileDivider(),

              _ProfileRow(
                icon: Icons.bookmark_border_rounded,
                title: 'Saved places',
                subtitle: 'Your saved destinations',
                onTap: _showSavedPlaces,
              ),

              const _ProfileDivider(),

              _ProfileRow(
                icon: Icons.history_rounded,
                title: 'Recent activity',
                subtitle: 'View your recent RoadWise activity',
                onTap: _showRecentActivity,
              ),

              const SizedBox(height: 30),

              // ============================================================
              // PREFERENCES
              // ============================================================

              const _SectionTitle(title: 'Preferences'),

              const SizedBox(height: 8),

              _ProfileRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: _notificationsEnabled
                    ? 'Notifications are enabled'
                    : 'Notifications are disabled',
                onTap: _showNotificationSettings,
              ),

              const _ProfileDivider(),

              _ProfileRow(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: _appearance,
                onTap: _showAppearanceSettings,
              ),

              const _ProfileDivider(),

              _ProfileRow(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: _locationEnabled
                    ? 'Location services are enabled'
                    : 'Location services are disabled',
                onTap: _showLocationSettings,
              ),

              const SizedBox(height: 30),

              // ============================================================
              // SUPPORT
              // ============================================================

              const _SectionTitle(title: 'Support'),

              const SizedBox(height: 8),

              _ProfileRow(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help with RoadWise',
                onTap: _showHelpAndSupport,
              ),
              _ProfileRow(
  icon: Icons.info_outline_rounded,
  title: 'About RoadWise',
  subtitle: 'Learn more about the app',
  onTap: _showAboutRoadWise,
),

_ProfileRow(
  icon: Icons.logout_rounded,
  title: 'Logout',
  subtitle: 'Sign out of this RoadWise account',
  onTap: widget.onLogout,
),

const SizedBox(height: 20),

              const _ProfileDivider(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PERSONAL INFORMATION
  // ==========================================================================

  void _showPersonalInformation() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Personal information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text.trim().isEmpty
                      ? 'RoadWise user'
                      : nameController.text.trim();

                  _email = emailController.text.trim().isEmpty
                      ? 'user@roadwise.com'
                      : emailController.text.trim();

                  _phone = phoneController.text.trim().isEmpty
                      ? '+91 00000 00000'
                      : phoneController.text.trim();
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // SAVED PLACES
  // ==========================================================================

  void _showSavedPlaces() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved places',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (_savedPlaces.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('You have no saved places yet.'),
                  )
                else
                  ..._savedPlaces.map(
                    (place) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(place),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$place selected'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // RECENT ACTIVITY
  // ==========================================================================

  void _showRecentActivity() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ..._recentActivity.map(
                  (activity) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_rounded),
                    title: Text(activity),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // NOTIFICATIONS
  // ==========================================================================

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Notifications'),
              content: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow notifications'),
                subtitle: const Text(
                  'Receive alerts and updates from RoadWise.',
                ),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setDialogState(() {
                    _notificationsEnabled = value;
                  });

                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // APPEARANCE
  // ==========================================================================

  void _showAppearanceSettings() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Appearance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppearanceOption(
                title: 'System default',
                value: 'System default',
                selected: _appearance == 'System default',
                onTap: () {
                  widget.onThemeModeChanged(ThemeMode.system);
                  Navigator.pop(dialogContext);
                },
              ),
              _AppearanceOption(
                title: 'Light',
                value: 'Light',
                selected: _appearance == 'Light',
                onTap: () {
                  widget.onThemeModeChanged(ThemeMode.light);
                  Navigator.pop(dialogContext);
                },
              ),
              _AppearanceOption(
                title: 'Dark',
                value: 'Dark',
                selected: _appearance == 'Dark',
                onTap: () {
                  widget.onThemeModeChanged(ThemeMode.dark);
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // LOCATION
  // ==========================================================================

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Location'),
              content: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use my location'),
                subtitle: const Text(
                  'Allow RoadWise to use your location for nearby services.',
                ),
                value: _locationEnabled,
                onChanged: (value) {
                  setDialogState(() {
                    _locationEnabled = value;
                  });

                  setState(() {
                    _locationEnabled = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // HELP & SUPPORT
  // ==========================================================================

  void _showHelpAndSupport() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Frequently asked questions'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'FAQ section will be available here.',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Contact support'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'Support contact will be connected to the backend later.',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Report a problem'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage(
                      'Problem reporting will be connected later.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // ABOUT
  // ==========================================================================

  void _showAboutRoadWise() {
    showAboutDialog(
      context: context,
      applicationName: 'RoadWise',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.directions_car_rounded,
        size: 42,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: const [
        Text(
          'RoadWise is a smart transportation system designed to make '
          'urban travel, parking and navigation more convenient.',
        ),
      ],
    );
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ============================================================================
// PROFILE ROW
// ============================================================================

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIVIDER
// ============================================================================

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 61),
      child: Divider(
        height: 1,
        color: colors.outlineVariant,
      ),
    );
  }
}

// ============================================================================
// AVATAR
// ============================================================================

class _ProfileAvatar extends StatelessWidget {
  final double size;
  final Color color;
  final Color background;

  const _ProfileAvatar({
    required this.size,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.48,
        color: color,
      ),
    );
  }
}

// ============================================================================
// APPEARANCE OPTION
// ============================================================================

class _AppearanceOption extends StatelessWidget {
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Radio<String>(
        value: value,
        groupValue: selected ? value : null,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    );
  }
}