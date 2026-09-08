import 'dart:ui';
import 'package:flutter/material.dart';
import '../../screens/parking/parking_page.dart';
import '../../screens/ev/ev_page.dart';

/// RoadWise palette — blue grain-gradient backdrop + frosted glass cards,
/// styled after the fintech-app reference (dark glass cards, warm gradient
/// hero blob, pill bottom nav, badge-style list rows).
class _RWColors {
  static const glassFill = Color(0x14FFFFFF); // white @ ~8%
  static const glassBorder = Color(0x26FFFFFF); // white @ ~15%
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xCCE9F1FF);
  static const textMuted = Color(0x99E9F1FF);

  // warm accent used sparingly for the hero card, echoing the reference's
  // orange glow / balance-card gradient against the cool blue backdrop
  static const heroGradient = [Color(0xFFFFB37C), Color(0xFFFF7A59)];

  // All functional icons live in this orange family — kept light/saturated
  // enough to stay visible against the blue gradient background.
  static const iconOrange = Color(0xFFFFA352); // primary icon color
  static const iconOrangeLight = Color(0xFFFFC38C); // lighter shade
  static const iconOrangeDeep = Color(0xFFFF7A33); // deeper shade

  static const traffic = Color(0xFFFFA352);
  static const parking = Color(0xFFFFC38C);
  static const evCharging = Color(0xFFFF7A33);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Your exact blue grain-gradient image, shipped alongside this
          // file at assets/images/home_bg.jpg — copy that folder into
          // your project root and register it in pubspec.yaml:
          //   flutter:
          //     assets:
          //       - assets/images/home_bg.jpg
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Subtle scrim for text legibility.
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.12)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _RWColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Welcome to RoadWise',
                            style: TextStyle(
                              fontSize: 15,
                              color: _RWColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      _GlassCircle(
                        size: 44,
                        child: const Icon(Icons.person_outline,
                            color: _RWColors.iconOrange),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Search bar — frosted glass pill
                  _GlassContainer(
                    borderRadius: 18,
                    padding: EdgeInsets.zero,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Where do you want to go?',
                        hintStyle: const TextStyle(color: _RWColors.textMuted),
                        prefixIcon: const Icon(Icons.search,
                            color: _RWColors.iconOrange),
                        suffixIcon: const Icon(Icons.mic_none,
                            color: _RWColors.iconOrangeLight),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Hero card — headline traffic status + sparkline,
                  // echoing the reference app's gradient balance card.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _RWColors.heroGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A59).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
               Expanded(
                  child: _QuickAction(
                  icon: Icons.ev_station,
                  label: 'EV Charging',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

                  const SizedBox(height: 24),

                  const _SectionTitle('Quick actions'),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionIcon(
                        icon: Icons.local_parking,
                        label: 'Parking',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParkingPage(),
                            ),
                          );
                        },
                      ),
                      _QuickActionIcon(
                        icon: Icons.ev_station,
                        label: 'EV Charging',
                      ),
                      _QuickActionIcon(
                        icon: Icons.traffic,
                        label: 'Traffic',
                      ),
                      _QuickActionIcon(
                        icon: Icons.local_shipping,
                        label: 'Freight',
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  const _SectionTitle('Live mobility status'),
                  const SizedBox(height: 14),

                  _GlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: const [
                        _StatusRow(
                          icon: Icons.traffic,
                          title: 'Traffic',
                          value: 'Moderate',
                          badgeColor: _RWColors.traffic,
                        ),
                        _RWDivider(),
                        _StatusRow(
                          icon: Icons.local_parking,
                          title: 'Parking',
                          value: 'Available',
                          badgeColor: _RWColors.parking,
                        ),
                        _RWDivider(),
                        _StatusRow(
                          icon: Icons.ev_station,
                          title: 'EV Chargers',
                          value: '6 nearby',
                          badgeColor: _RWColors.evCharging,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Recommendation
                  _GlassContainer(
                    borderRadius: 22,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GlassCircle(
                          size: 40,
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: _RWColors.iconOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RoadWise recommendation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _RWColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Traffic is moderate. Consider checking parking availability before starting your journey.',
                                style: TextStyle(
                                  color: _RWColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _RWBottomBar(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _RWColors.textPrimary,
      ),
    );
  }
}

/// Frosted glass panel — BackdropFilter blur + translucent fill/border.
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _RWColors.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _RWColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;
  const _GlassCircle({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _RWColors.glassFill,
            shape: BoxShape.circle,
            border: Border.all(color: _RWColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          _GlassCircle(
            size: 56,
            child: Icon(icon, color: _RWColors.iconOrange, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _RWColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color badgeColor;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _RWColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _RWColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RWDivider extends StatelessWidget {
  const _RWDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withValues(alpha: 0.08), height: 1);
  }
}

/// Purely decorative bottom bar — no new routes wired up, matches the
/// reference app's minimal icon nav.
class _RWBottomBar extends StatelessWidget {
  const _RWBottomBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _GlassContainer(
        borderRadius: 26,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RWNavItem(icon: Icons.home_rounded, active: true),
            _RWNavItem(icon: Icons.chat_bubble_outline),
            _RWNavItem(icon: Icons.add_circle_outline),
            _RWNavItem(icon: Icons.bar_chart_rounded),
            _RWNavItem(icon: Icons.person_outline),
          ],
        ),
      ),
    );
  }
}

class _RWNavItem extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _RWNavItem({required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: active ? _RWColors.iconOrangeDeep : _RWColors.iconOrangeLight,
      ),
    );
  }
}

/// Lightweight area-sparkline, no chart package required.
class _SparklinePainter extends CustomPainter {
  final List<double> values; // normalized 0..1
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(i * dx, size.height * (1 - values[i]))
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => false;
}