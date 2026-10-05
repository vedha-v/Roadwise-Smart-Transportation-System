import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/traffic_api_service.dart';

const _delhiDefault = LatLng(28.6139, 77.209);

class TrafficPage extends StatefulWidget {
  const TrafficPage({super.key});

  @override
  State<TrafficPage> createState() => _TrafficPageState();
}

class _TrafficPageState extends State<TrafficPage> {
  final TrafficApiService _api = TrafficApiService();
  TrafficSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTraffic();
  }

  Future<void> _loadTraffic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await _api.getTraffic(
        latitude: _delhiDefault.latitude,
        longitude: _delhiDefault.longitude,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadTraffic,
            tooltip: 'Refresh traffic',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTraffic,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (_isLoading && snapshot == null)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && snapshot == null)
              _buildError()
            else if (snapshot != null) ...[
              _buildStatus(snapshot),
              const SizedBox(height: 14),
              _buildMap(snapshot),
              const SizedBox(height: 18),
              _buildIncidentHeading(snapshot),
              const SizedBox(height: 8),
              if (snapshot.incidents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: Text('No reported incidents nearby')),
                )
              else
                for (final incident in snapshot.incidents)
                  _buildIncident(incident),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(TrafficSnapshot snapshot) {
    final color = _statusColor(snapshot.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.traffic, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snapshot.status,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, color: color),
                ),
              ),
              if (snapshot.stale)
                const Chip(
                  avatar: Icon(Icons.history, size: 16),
                  label: Text('Saved'),
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(Icons.circle, color: Color(0xFF37865A), size: 10),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(
                value: '${snapshot.currentSpeed.round()}',
                label: 'km/h now',
              ),
              const SizedBox(width: 24),
              _Metric(
                value: '${snapshot.freeFlowSpeed.round()}',
                label: 'km/h free flow',
              ),
              const SizedBox(width: 24),
              _Metric(value: '${snapshot.congestionPercent}%', label: 'slower'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${snapshot.source}  ·  ${_formatTime(snapshot.capturedAt)}  ·  Delhi fixed location',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (snapshot.stale)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'TomTom is unavailable. Showing the last saved reading.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(TrafficSnapshot snapshot) {
    final flowPoints = snapshot.segment
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    final incidentMarkers = snapshot.incidents
        .where((item) => item.latitude != null && item.longitude != null)
        .map(
          (item) => Marker(
            point: LatLng(item.latitude!, item.longitude!),
            width: 36,
            height: 36,
            child: Tooltip(
              message: item.type,
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFCE5138),
                size: 28,
              ),
            ),
          ),
        )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 270,
        child: FlutterMap(
          options: MapOptions(initialCenter: _delhiDefault, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.roadwise.app',
            ),
            if (flowPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: flowPoints,
                    color: _statusColor(snapshot.status),
                    strokeWidth: 6,
                  ),
                ],
              ),
            MarkerLayer(markers: incidentMarkers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
              alignment: AttributionAlignment.bottomRight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentHeading(TrafficSnapshot snapshot) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Nearby incidents',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text('${snapshot.incidents.length} reported'),
      ],
    );
  }

  Widget _buildIncident(TrafficIncident incident) {
    final location = [
      incident.from,
      incident.to,
    ].where((value) => value != null && value.isNotEmpty).join(' to ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFF827A).withValues(alpha: 0.16),
        foregroundColor: const Color(0xFFFFA29B),
        child: const Icon(Icons.warning_amber_rounded),
      ),
      title: Text(incident.type),
      subtitle: Text(
        [
          if (location.isNotEmpty) location,
          incident.severity,
          if (incident.delaySeconds > 0)
            '${(incident.delaySeconds / 60).ceil()} min delay',
        ].join(' · '),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Traffic data is unavailable',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadTraffic,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Closed' || status == 'Heavy') {
      return const Color(0xFFFF827A);
    }
    if (status == 'Moderate') return const Color(0xFFFFC38C);
    return const Color(0xFF69D598);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return 'Updated $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
