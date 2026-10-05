import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/booking_service.dart';
import '../../services/parking_api_service.dart';

class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final ParkingApiService _api = ParkingApiService();
  List<ParkingFacility> _facilities = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final facilities = await _api.getNearbyParking();
      if (!mounted) return;
      setState(() {
        _facilities = facilities;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFacility(ParkingFacility facility) async {
    final reserved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ParkingSlotsPage(facility: facility),
      ),
    );
    if (!mounted || reserved != true) return;
    await _loadFacilities();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parking reservation confirmed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchQuery.trim().toLowerCase();
    final facilities = _facilities
        .where((facility) => facility.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Parking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find a parking spot', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Nearby facilities with verified parking spaces.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search parking facilities',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Text('Nearby parking', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Expanded(child: _buildFacilityContent(facilities)),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityContent(List<ParkingFacility> facilities) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _MessageState(
        message: 'Could not load nearby parking.\n$_errorMessage',
        onRetry: _loadFacilities,
      );
    }
    if (facilities.isEmpty) {
      return _MessageState(
        message: _searchQuery.trim().isEmpty
            ? 'No parking facilities were found nearby.'
            : 'No facilities match your search.',
        onRetry: _searchQuery.trim().isEmpty ? _loadFacilities : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFacilities,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: facilities.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final facility = facilities[index];
          final hasSlots = facility.verifiedSlotCount > 0;
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_parking)),
              title: Text(
                facility.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${facility.distanceKm.toStringAsFixed(1)} km away\n'
                '${facility.isDemo ? 'DEMO ONLY · sample facility\n' : ''}'
                '${hasSlots ? '${facility.verifiedSlotCount} verified spaces' : 'No verified space inventory'}',
              ),
              isThreeLine: true,
              trailing: Icon(
                hasSlots ? Icons.chevron_right : Icons.lock_outline,
              ),
              enabled: hasSlots,
              onTap: hasSlots ? () => _openFacility(facility) : null,
            ),
          );
        },
      ),
    );
  }
}

class ParkingSlotsPage extends StatefulWidget {
  final ParkingFacility facility;

  const ParkingSlotsPage({super.key, required this.facility});

  @override
  State<ParkingSlotsPage> createState() => _ParkingSlotsPageState();
}

class _ParkingSlotsPageState extends State<ParkingSlotsPage> {
  final ParkingApiService _api = ParkingApiService();
  late DateTime _startsAt;
  late DateTime _endsAt;
  List<ParkingSlot> _slots = [];
  int? _selectedSlotId;
  bool _isLoading = true;
  bool _isReserving = false;
  String? _errorMessage;
  LatLng? _currentLocation;
  String? _locationMessage;
  bool _isLoadingLocation = true;

  bool get _hasValidInterval =>
      _startsAt.isAfter(DateTime.now()) &&
      _endsAt.isAfter(_startsAt) &&
      _endsAt.difference(_startsAt) <= const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _startsAt = DateTime.now().add(const Duration(hours: 1));
    _endsAt = _startsAt.add(const Duration(hours: 1));
    _loadSlots();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationMessage = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is disabled. Enable it in app settings to show your position.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _handleLocationAction() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      final opened = await Geolocator.openLocationSettings();
      if (!opened && mounted) {
        setState(() {
          _locationMessage = 'Could not open location settings.';
        });
      }
      return;
    }

    if (await Geolocator.checkPermission() ==
        LocationPermission.deniedForever) {
      final opened = await Geolocator.openAppSettings();
      if (!opened && mounted) {
        setState(() {
          _locationMessage = 'Could not open app settings.';
        });
      }
      return;
    }

    await _loadCurrentLocation();
  }

  Future<void> _loadSlots() async {
    if (!_hasValidInterval) {
      setState(() {
        _slots = [];
        _selectedSlotId = null;
        _isLoading = false;
        _errorMessage = 'Choose a future time range of up to 24 hours.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedSlotId = null;
    });
    try {
      final slots = await _api.getAvailableSlots(
        widget.facility,
        _startsAt,
        _endsAt,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _selectedSlotId = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateTime({required bool selectingStart}) async {
    final current = selectingStart ? _startsAt : _endsAt;
    final now = DateTime.now();
    final initialDate = current.isBefore(now) ? now : current;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (selectingStart) {
        _startsAt = selected;
        if (!_endsAt.isAfter(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = selected;
      }
    });
    await _loadSlots();
  }

  Future<void> _reserve() async {
    final slotId = _selectedSlotId;
    if (slotId == null || _isReserving) return;
    setState(() => _isReserving = true);
    try {
      await BookingService.createBooking(
        slotId: slotId,
        startsAt: _startsAt,
        endsAt: _endsAt,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reserve this space: $error')),
      );
      await _loadSlots();
    } finally {
      if (mounted) setState(() => _isReserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.facility.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a parking space', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${_currentLocation != null
                  ? '${_distanceToFacilityKm.toStringAsFixed(1)} km away'
                  : _isLoadingLocation
                  ? 'Finding your distance…'
                  : '${widget.facility.distanceKm.toStringAsFixed(1)} km from search area'}'
              '${widget.facility.isDemo ? ' · DEMO ONLY' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _ParkingRouteMap(
              currentLocation: _currentLocation,
              parkingLocation: widget.facility.location,
              facilityName: widget.facility.name,
              distanceKm: _currentLocation == null
                  ? null
                  : _distanceToFacilityKm,
              isLoadingLocation: _isLoadingLocation,
              locationMessage: _locationMessage,
              onRetryLocation: _handleLocationAction,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateTime(selectingStart: true),
                    icon: const Icon(Icons.login),
                    label: Text('From\n${_formatDateTime(context, _startsAt)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateTime(selectingStart: false),
                    icon: const Icon(Icons.logout),
                    label: Text('Until\n${_formatDateTime(context, _endsAt)}'),
                  ),
                ),
              ],
            ),
            if (widget.facility.isDemo) ...[
              const SizedBox(height: 12),
              Text(
                'DEMO ONLY: sample facility and spaces, not real inventory.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('Available spaces', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(child: _buildSlots()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selectedSlotId == null || _isReserving ? null : _reserve,
          icon: _isReserving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.event_available),
          label: Text(_isReserving ? 'Reserving...' : 'Reserve selected space'),
        ),
      ),
    );
  }

  double get _distanceToFacilityKm {
    final current = _currentLocation;
    if (current == null) return widget.facility.distanceKm;
    return Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          widget.facility.location.latitude,
          widget.facility.location.longitude,
        ) /
        1000;
  }

  Widget _buildSlots() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _MessageState(message: _errorMessage!, onRetry: _loadSlots);
    }
    if (_slots.isEmpty) {
      return _MessageState(
        message: 'No verified spaces are available for this time range.',
        onRetry: _loadSlots,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSlots,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        itemCount: _slots.length,
        itemBuilder: (context, index) {
          final slot = _slots[index];
          final selected = slot.id == _selectedSlotId;
          return OutlinedButton(
            onPressed: () => setState(() => _selectedSlotId = slot.id),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_parking),
                const SizedBox(height: 6),
                Text(slot.slotCode, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParkingRouteMap extends StatefulWidget {
  final LatLng? currentLocation;
  final LatLng parkingLocation;
  final String facilityName;
  final double? distanceKm;
  final bool isLoadingLocation;
  final String? locationMessage;
  final VoidCallback onRetryLocation;

  const _ParkingRouteMap({
    required this.currentLocation,
    required this.parkingLocation,
    required this.facilityName,
    required this.distanceKm,
    required this.isLoadingLocation,
    required this.locationMessage,
    required this.onRetryLocation,
  });

  @override
  State<_ParkingRouteMap> createState() => _ParkingRouteMapState();
}

class _ParkingRouteMapState extends State<_ParkingRouteMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant _ParkingRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMap();
      });
    }
  }

  void _fitMap() {
    final current = widget.currentLocation;
    if (current == null) return;

    final meters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      widget.parkingLocation.latitude,
      widget.parkingLocation.longitude,
    );
    if (meters < 25) {
      _mapController.move(widget.parkingLocation, 16);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([current, widget.parkingLocation]),
        padding: const EdgeInsets.all(52),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final current = widget.currentLocation;
    final mapCenter = current == null
        ? widget.parkingLocation
        : LatLng(
            (current.latitude + widget.parkingLocation.latitude) / 2,
            (current.longitude + widget.parkingLocation.longitude) / 2,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: current == null ? 15 : 13,
                onMapReady: _fitMap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.roadwise.app',
                ),
                if (current != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [current, widget.parkingLocation],
                        color: const Color(0xFFFFA352),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.parkingLocation,
                      width: 48,
                      height: 56,
                      child: Tooltip(
                        message: widget.facilityName,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFF7A59),
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (current != null)
                      Marker(
                        point: current,
                        width: 48,
                        height: 48,
                        child: Tooltip(
                          message: 'Your current location',
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFA352),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFFFFA352),
                              size: 23,
                            ),
                          ),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Icon(
                  current == null
                      ? Icons.location_searching_rounded
                      : Icons.route_rounded,
                  color: const Color(0xFFFFA352),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current == null
                            ? 'Parking location'
                            : 'Your location to parking',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        current == null
                            ? widget.isLoadingLocation
                                  ? 'Finding your current location…'
                                  : widget.locationMessage ??
                                        'Current location unavailable'
                            : '${widget.distanceKm!.toStringAsFixed(2)} km straight-line distance',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (current == null && !widget.isLoadingLocation)
                  TextButton(
                    onPressed: widget.onRetryLocation,
                    child: Text(
                      widget.locationMessage == null ? 'Retry' : 'Settings',
                    ),
                  )
                else if (widget.isLoadingLocation)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date = MaterialLocalizations.of(context).formatShortDate(local);
  final time = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return '$date $time';
}

class _MessageState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _MessageState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
