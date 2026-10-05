import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/freight_route_service.dart';

class FreightPage extends StatelessWidget {
  const FreightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FreightDashboard();
  }
}

class _FreightDashboard extends StatefulWidget {
  const _FreightDashboard();

  @override
  State<_FreightDashboard> createState() => _FreightDashboardState();
}

class _FreightDashboardState extends State<_FreightDashboard> {
  final FreightRouteService _routeService = FreightRouteService();
  final TextEditingController _originController = TextEditingController(
    text: 'Delhi, India',
  );
  final TextEditingController _destinationController = TextEditingController(
    text: 'Jaipur, India',
  );
  List<LatLng> _routePoints = const [];
  FreightRoutePlan? _routePlan;
  List<RouteTrafficCheck> _trafficChecks = const [];
  String? _routeError;
  bool _isPlanningRoute = false;
  bool _isRefreshingTraffic = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _planRoute();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _planRoute() async {
    final requestId = ++_requestId;
    setState(() {
      _isPlanningRoute = true;
      _isRefreshingTraffic = true;
      _routeError = null;
      _routePlan = null;
      _routePoints = const [];
      _trafficChecks = const [];
    });

    try {
      final plan = await _routeService.planRoute(
        origin: _originController.text,
        destination: _destinationController.text,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _routePlan = plan;
        _routePoints = plan.points;
        _isPlanningRoute = false;
      });
      await _refreshRouteTraffic(plan.points, requestId: requestId);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _routeError = error.toString().replaceFirst('Exception: ', '');
        _isPlanningRoute = false;
        _isRefreshingTraffic = false;
      });
    }
  }

  Future<void> _refreshRouteTraffic(
    List<LatLng> routePoints, {
    required int requestId,
  }) async {
    setState(() {
      _isRefreshingTraffic = true;
    });

    try {
      final checks = await _routeService.checkTrafficAlongRoute(routePoints);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _trafficChecks = checks;
        _isRefreshingTraffic = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _routeError = error.toString().replaceFirst('Exception: ', '');
        _isRefreshingTraffic = false;
      });
    }
  }

  Future<void> _refreshTraffic() {
    return _refreshRouteTraffic(_routePoints, requestId: _requestId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Freight',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _isRefreshingTraffic || _isPlanningRoute
                  ? null
                  : _refreshTraffic,
              tooltip: 'Refresh live traffic',
              icon: _isRefreshingTraffic
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Color(0xFFFFA352),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Color(0xCCE9F1FF),
                tabs: [
                  Tab(text: 'Plan'),
                  Tab(text: 'Stops'),
                  Tab(text: 'Reservation'),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1732), Color(0xFF122A4A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _SummaryCard(
                    origin: _originController.text,
                    destination: _destinationController.text,
                    distanceMeters: _routePlan?.distanceMeters,
                    isPlanningRoute: _isPlanningRoute,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PlanTab(
                        originController: _originController,
                        destinationController: _destinationController,
                        routePoints: _routePoints,
                        routePlan: _routePlan,
                        trafficChecks: _trafficChecks,
                        routeError: _routeError,
                        isPlanningRoute: _isPlanningRoute,
                        isRefreshingTraffic: _isRefreshingTraffic,
                        onPlanRoute: _planRoute,
                        onRefreshTraffic: _refreshTraffic,
                      ),
                      const _StopsTab(),
                      const _ReservationTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String origin;
  final String destination;
  final double? distanceMeters;
  final bool isPlanningRoute;

  const _SummaryCard({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.isPlanningRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB37C), Color(0xFFFF7A59)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A59).withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlanningRoute
                      ? 'ROUTE PLANNER  ·  UPDATING'
                      : 'FREIGHT ROUTE  ·  LIVE TRAFFIC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Freight overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Badge(
                      label: distanceMeters == null
                          ? '$origin → $destination'
                          : '${_formatDistance(distanceMeters!)} route',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final List<LatLng> routePoints;
  final FreightRoutePlan? routePlan;
  final List<RouteTrafficCheck> trafficChecks;
  final String? routeError;
  final bool isPlanningRoute;
  final bool isRefreshingTraffic;
  final Future<void> Function() onPlanRoute;
  final Future<void> Function() onRefreshTraffic;

  const _PlanTab({
    required this.originController,
    required this.destinationController,
    required this.routePoints,
    required this.routePlan,
    required this.trafficChecks,
    required this.routeError,
    required this.isPlanningRoute,
    required this.isRefreshingTraffic,
    required this.onPlanRoute,
    required this.onRefreshTraffic,
  });

  @override
  Widget build(BuildContext context) {
    final availableSnapshotCount = trafficChecks
        .where((check) => check.snapshot != null)
        .length;
    final failedCheckCount = trafficChecks
        .where((check) => check.error != null)
        .length;
    final overallTraffic = _overallTrafficStatus(trafficChecks);
    final routeTrafficError = failedCheckCount == 0
        ? null
        : 'Traffic data unavailable at $failedCheckCount of ${trafficChecks.length} route checkpoints.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        const Text(
          'Trip overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan a route',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _PlaceField(
                controller: originController,
                label: 'Starting point',
                hint: 'e.g. Delhi, India',
                icon: Icons.trip_origin_rounded,
              ),
              const SizedBox(height: 10),
              _PlaceField(
                controller: destinationController,
                label: 'Destination',
                hint: 'e.g. Jaipur, India',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isPlanningRoute ? null : onPlanRoute,
                  icon: isPlanningRoute
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.alt_route_rounded),
                  label: Text(
                    isPlanningRoute
                        ? 'Finding route...'
                        : 'Plan route & traffic',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA352),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (routeError != null) ...[
          const SizedBox(height: 10),
          _TrafficErrorNotice(
            message: routeError!,
            onRetry: isPlanningRoute ? null : onPlanRoute,
          ),
        ],
        const SizedBox(height: 14),
        _FreightRouteMap(
          routePoints: routePoints,
          originLabel: originController.text,
          destinationLabel: destinationController.text,
          trafficChecks: trafficChecks,
        ),
        const SizedBox(height: 6),
        const Text(
          'Map and place data © OpenStreetMap contributors · Route by OSRM · Traffic by RoadWise',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99E9F1FF), fontSize: 9),
        ),
        const SizedBox(height: 14),
        const Text(
          'LIVE STATUS ALONG THIS ROUTE',
          style: TextStyle(
            color: Color(0xCCE9F1FF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _StatusTile(
              icon: Icons.traffic_rounded,
              title: 'Worst checkpoint',
              value:
                  overallTraffic ??
                  (isRefreshingTraffic ? 'Checking' : 'Unavailable'),
              detail: trafficChecks.isEmpty
                  ? 'Checking along route'
                  : '$availableSnapshotCount/${trafficChecks.length} checkpoints reporting',
              color: overallTraffic == null
                  ? const Color(0xFFFFC38C)
                  : _trafficColor(overallTraffic),
              onTap: isRefreshingTraffic ? null : onRefreshTraffic,
            ),
            _StatusTile(
              icon: Icons.schedule_rounded,
              title: 'Estimated arrival',
              value: routePlan == null
                  ? '—'
                  : _formatDuration(routePlan!.durationSeconds),
              detail: routePlan == null
                  ? 'Plan a route first'
                  : 'Route estimate',
              color: const Color(0xFF82B8FF),
            ),
            _StatusTile(
              icon: Icons.route_rounded,
              title: 'Route distance',
              value: routePlan == null
                  ? '—'
                  : _formatDistance(routePlan!.distanceMeters),
              detail: routePlan == null ? 'Awaiting route' : 'Driving distance',
              color: const Color(0xFF69D598),
            ),
            const _StatusTile(
              icon: Icons.inventory_2_rounded,
              title: 'Cargo condition',
              value: '—',
              detail: 'No vehicle telemetry connected',
              color: Color(0xFFD5A7FF),
            ),
          ],
        ),
        if (routeTrafficError != null) ...[
          const SizedBox(height: 10),
          _TrafficErrorNotice(
            message: routeTrafficError,
            onRetry: isRefreshingTraffic ? null : onRefreshTraffic,
          ),
        ],
        if (trafficChecks.isNotEmpty) ...[
          const SizedBox(height: 14),
          _RouteTrafficDetails(checks: trafficChecks),
        ],
      ],
    );
  }
}

class _FreightRouteMap extends StatefulWidget {
  final List<LatLng> routePoints;
  final String originLabel;
  final String destinationLabel;
  final List<RouteTrafficCheck> trafficChecks;

  const _FreightRouteMap({
    required this.routePoints,
    required this.originLabel,
    required this.destinationLabel,
    required this.trafficChecks,
  });

  @override
  State<_FreightRouteMap> createState() => _FreightRouteMapState();
}

class _FreightRouteMapState extends State<_FreightRouteMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant _FreightRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routePoints != widget.routePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRoute();
      });
    }
  }

  void _fitRoute() {
    if (widget.routePoints.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(widget.routePoints),
        padding: const EdgeInsets.all(44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routePoints.length < 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 230,
          color: Colors.white.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: Color(0xFFFFA352), size: 32),
              SizedBox(height: 8),
              Text(
                'Plan a route to see its map and traffic',
                style: TextStyle(
                  color: Color(0xCCE9F1FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    widget.routePoints[widget.routePoints.length ~/ 2],
                initialZoom: 6.8,
                onMapReady: _fitRoute,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.roadwise.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints,
                      color: Colors.white.withValues(alpha: 0.8),
                      strokeWidth: 8,
                    ),
                    Polyline(
                      points: widget.routePoints,
                      color: const Color(0xFFFF8A45),
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.routePoints.first,
                      width: 58,
                      height: 54,
                      child: const _RoutePin(label: 'A', isDestination: false),
                    ),
                    Marker(
                      point: widget.routePoints.last,
                      width: 58,
                      height: 54,
                      child: const _RoutePin(label: 'B', isDestination: true),
                    ),
                    for (final check in widget.trafficChecks)
                      if (check.point != widget.routePoints.first &&
                          check.point != widget.routePoints.last)
                        Marker(
                          point: check.point,
                          width: 34,
                          height: 34,
                          child: _TrafficMapMarker(
                            status: check.snapshot?.status ?? 'Unavailable',
                          ),
                        ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                  alignment: AttributionAlignment.bottomRight,
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE60B1732),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${widget.originLabel}  →  ${widget.destinationLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePin extends StatelessWidget {
  final String label;
  final bool isDestination;

  const _RoutePin({required this.label, required this.isDestination});

  @override
  Widget build(BuildContext context) {
    final color = isDestination
        ? const Color(0xFFFF7A59)
        : const Color(0xFF278A69);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10213C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Icon(Icons.location_on_rounded, color: color, size: 27),
      ],
    );
  }
}

class _TrafficMapMarker extends StatelessWidget {
  final String status;

  const _TrafficMapMarker({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Unavailable'
        ? const Color(0xFFFF827A)
        : _trafficColor(status);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.traffic_rounded,
        color: Color(0xFF10213C),
        size: 17,
      ),
    );
  }
}

class _PlaceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _PlaceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xCCE9F1FF), fontSize: 12),
        hintStyle: const TextStyle(color: Color(0x99E9F1FF), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFFFA352), size: 20),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFA352)),
        ),
      ),
    );
  }
}

class _RouteTrafficDetails extends StatelessWidget {
  final List<RouteTrafficCheck> checks;

  const _RouteTrafficDetails({required this.checks});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Traffic checkpoints',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < checks.length; index++) ...[
            if (index > 0)
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 18),
            _TrafficCheckpointRow(index: index, check: checks[index]),
          ],
        ],
      ),
    );
  }
}

class _TrafficCheckpointRow extends StatelessWidget {
  final int index;
  final RouteTrafficCheck check;

  const _TrafficCheckpointRow({required this.index, required this.check});

  @override
  Widget build(BuildContext context) {
    final snapshot = check.snapshot;
    final status = snapshot?.status ?? 'Unavailable';
    final color = snapshot == null
        ? const Color(0xFFFF827A)
        : _trafficColor(status);
    final speed = snapshot == null
        ? check.error ?? 'Traffic reading unavailable'
        : '${snapshot.currentSpeed.round()} km/h'
              '${snapshot.stale ? '  ·  saved reading' : ''}';

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checkpoint ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${check.point.latitude.toStringAsFixed(3)}, ${check.point.longitude.toStringAsFixed(3)}  ·  $speed',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xCCE9F1FF), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback? onTap;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCE9F1FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: color.withValues(alpha: 0.9),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0x99E9F1FF), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrafficErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _TrafficErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF827A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF827A).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFFFA29B),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFD9D6), fontSize: 11),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Color _trafficColor(String status) {
  if (status == 'Closed' || status == 'Heavy') {
    return const Color(0xFFFF827A);
  }
  if (status == 'Moderate') return const Color(0xFFFFC38C);
  return const Color(0xFF69D598);
}

String? _overallTrafficStatus(List<RouteTrafficCheck> checks) {
  final statuses = checks
      .where((check) => check.snapshot != null)
      .map((check) => check.snapshot!.status)
      .toList();
  if (statuses.isEmpty) return null;
  const severity = {'Closed': 4, 'Heavy': 3, 'Moderate': 2, 'Free flowing': 1};
  statuses.sort((a, b) => (severity[b] ?? 0).compareTo(severity[a] ?? 0));
  return statuses.first;
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).round()} km';
}

String _formatDuration(double seconds) {
  final totalMinutes = (seconds / 60).round();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours hr';
  return '$hours hr $minutes min';
}

class _StopsTab extends StatelessWidget {
  const _StopsTab();

  @override
  Widget build(BuildContext context) {
    final stopItems = [
      {
        'title': 'Metro Bistro',
        'subtitle': 'Restaurant • 4.8 km away',
        'icon': Icons.restaurant_rounded,
        'tag': 'Meal break',
      },
      {
        'title': 'Green Rest Hub',
        'subtitle': 'Rest stop • Quiet parking',
        'icon': Icons.hotel_rounded,
        'tag': 'Rest area',
      },
      {
        'title': 'A1 Fuel Lounge',
        'subtitle': 'Truck stop • 24/7 services',
        'icon': Icons.local_gas_station_rounded,
        'tag': 'Fuel',
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        const Text(
          'Recommended stops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...stopItems.map((stop) => _StopCard(stop: stop)),
      ],
    );
  }
}

class _ReservationTab extends StatelessWidget {
  const _ReservationTab();

  @override
  Widget build(BuildContext context) {
    final reservations = [
      {
        'title': 'Driver rest bay',
        'time': '8:00 AM - 10:00 AM',
        'status': 'Confirmed',
      },
      {
        'title': 'Truck service lounge',
        'time': '12:30 PM - 1:00 PM',
        'status': 'Pending',
      },
      {
        'title': 'Meal stop table',
        'time': '6:15 PM - 7:00 PM',
        'status': 'Available',
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        const Text(
          'Reservations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...reservations.map((reservation) {
          final isConfirmed = reservation['status'] == 'Confirmed';
          final accent = isConfirmed
              ? const Color(0xFF69D598)
              : const Color(0xFFFFA352);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.event_available_rounded, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation['time'] as String,
                        style: const TextStyle(
                          color: Color(0xCCE9F1FF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    reservation['status'] as String,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _StopCard extends StatelessWidget {
  final Map<String, dynamic> stop;

  const _StopCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    final icon = stop['icon'] as IconData;
    final title = stop['title'] as String;
    final subtitle = stop['subtitle'] as String;
    final tag = stop['tag'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA352).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFFFA352)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xCCE9F1FF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
