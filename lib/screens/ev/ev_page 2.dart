import 'dart:async';
import 'dart:convert';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class EvPage extends StatefulWidget {
  const EvPage({super.key});

  @override
  State<EvPage> createState() => _EvPageState();
}

/// A charging station plus its computed distance from the current
/// location, so we can show "X km away" without recomputing later.
class _EvStation {
  final String name;
  final LatLng point;
  final double distanceKm;

  _EvStation({
    required this.name,
    required this.point,
    required this.distanceKm,
  });
}

class _EvPageState extends State<EvPage> {
  // ---------------------------------------------------------------------
  // HARDCODED TEST LOCATION
  // ---------------------------------------------------------------------
  // Connaught Place, New Delhi. Used instead of the device's real GPS
  // location so you can verify the EV lookup + distance calculation
  // against a spot that reliably has charging stations on Open Charge
  // Map within a 5km radius. Swap this out (or wire _getLocation() back
  // in) once you're done testing.
  static const LatLng _hardcodedLocation = LatLng(28.6329, 77.2195);
  static const bool _useHardcodedLocation = true;

  LatLng? currentLocation;
  List<_EvStation> stations = [];
  List<Marker> stationMarkers = [];

  bool isLoading = true;
  String? errorMessage;

  // Radius (km) we search at, in order. If the first (closest) radius
  // comes back with zero stations we automatically widen the search rather
  // than reporting a failure — a genuinely empty 5km radius is common in
  // smaller towns and rural areas, and isn't a bug.
  static const List<int> _searchRadiiKm = [5, 15, 30];
  int _lastSearchRadiusKm = _searchRadiiKm.first;

  // Open Charge Map — https://openchargemap.org. Free, purpose-built EV
  // charger database on its own domain, separate from OSM's Overpass
  // servers. Works without a key at low volume; get a free key at
  // https://openchargemap.org/site/develop/api and put it here to raise
  // your rate limit and be a good API citizen.
  static const String _openChargeMapKey = 'e47e1999-8427-428a-8037-c0e5ee959c19'; // optional: paste your key
  static const String _openChargeMapUrl =
      'https://api.openchargemap.io/v3/poi/';

  @override
  void initState() {
    super.initState();
    _loadEvStations();
  }

  /// Quick reachability check against a well-known, highly-available host.
  /// If this fails, the problem is general internet connectivity (emulator
  /// network config, VPN, firewall) — not anything specific to one API.
  Future<bool> _hasBasicInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('EV: basic connectivity check failed: $e');
      return false;
    }
  }

  Future<void> _loadEvStations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final LatLng? location;

      if (_useHardcodedLocation) {
        // Skip GPS entirely — use the fixed Delhi coordinate above.
        location = _hardcodedLocation;
        debugPrint(
          'EV: using hardcoded location lat=${location.latitude}, '
              'lng=${location.longitude}',
        );
      } else {
        final position = await _getLocation();
        if (position == null) {
          // errorMessage / isLoading already set inside _getLocation.
          return;
        }
        location = LatLng(position.latitude, position.longitude);
        debugPrint(
          'EV: got location lat=${location.latitude}, lng=${location.longitude}, '
              'accuracy=${position.accuracy}m',
        );
      }

      setState(() {
        currentLocation = location;
      });

      final online = await _hasBasicInternet();
      if (!online) {
        setState(() {
          errorMessage =
          'No internet reachable from this device/emulator at all '
              '(google.com did not respond). This is a network/emulator '
              'issue, not an app bug.';
          isLoading = false;
        });
        return;
      }

      await _findNearbyStationsWithWidening(location);
    } on TimeoutException {
      setState(() {
        errorMessage =
        'The charging station service timed out. Please try again.';
        isLoading = false;
      });
    } on SocketException {
      setState(() {
        errorMessage = 'No internet connection. Check your network and try again.';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('EV load error: $e');
      setState(() {
        errorMessage = 'Could not load EV charging stations.\n$e';
        isLoading = false;
      });
    }
  }

  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Location services are disabled.';
        isLoading = false;
      });
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Location permission denied.';
          isLoading = false;
        });
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Location permission is permanently denied.';
        isLoading = false;
      });
      return null;
    }

    return Geolocator.getCurrentPosition();
  }

  /// Tries each radius, widening automatically if a closer search comes
  /// back with zero stations. This is what stops a legitimately sparse
  /// area (small town, rural highway) from looking like a broken app.
  Future<void> _findNearbyStationsWithWidening(LatLng location) async {
    for (final radiusKm in _searchRadiiKm) {
      final found = await _findNearbyStations(location, radiusKm);

      if (found.isNotEmpty || radiusKm == _searchRadiiKm.last) {
        setState(() {
          stations = found;
          stationMarkers = _buildMarkers(found);
          _lastSearchRadiusKm = radiusKm;
          isLoading = false;
        });
        return;
      }
      // Zero results at this radius and we have a bigger one to try —
      // loop continues automatically.
    }
  }

  Future<List<_EvStation>> _findNearbyStations(
      LatLng location,
      int radiusKm,
      ) async {
    final url = Uri.parse(_openChargeMapUrl).replace(
      queryParameters: {
        'output': 'json',
        'latitude': '${location.latitude}',
        'longitude': '${location.longitude}',
        'distance': '$radiusKm',
        'distanceunit': 'KM',
        'maxresults': '100',
        'compact': 'true',
        'verbose': 'false',
        if (_openChargeMapKey.isNotEmpty) 'key': _openChargeMapKey,
      },
    );

    final response = await http
        .get(url, headers: {'User-Agent': 'RoadWiseApp/1.0'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      debugPrint(
        'EV: Open Charge Map returned ${response.statusCode}: '
            '${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );
      throw Exception(
        'Open Charge Map request failed (${response.statusCode}).',
      );
    }

    final List elements = jsonDecode(response.body) as List;

    debugPrint(
      'EV: Open Charge Map returned ${elements.length} stations for '
          'radius=${radiusKm}km around ${location.latitude},${location.longitude}',
    );

    final found = <_EvStation>[];

    for (final element in elements) {
      final addressInfo = element['AddressInfo'];
      if (addressInfo == null) continue;

      final latitude = (addressInfo['Latitude'] as num?)?.toDouble();
      final longitude = (addressInfo['Longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) continue;

      final name = (addressInfo['Title'] as String?)?.trim();
      final displayName =
      (name == null || name.isEmpty) ? 'EV Charging Station' : name;

      // Distance from the current (hardcoded or real) location to this
      // station, in kilometers. Geolocator.distanceBetween returns meters.
      final distanceMeters = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        latitude,
        longitude,
      );
      final distanceKm = distanceMeters / 1000;

      found.add(
        _EvStation(
          name: displayName,
          point: LatLng(latitude, longitude),
          distanceKm: distanceKm,
        ),
      );
    }

    // Closest stations first.
    found.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return found;
  }

  List<Marker> _buildMarkers(List<_EvStation> stations) {
    return stations.map((station) {
      return Marker(
        point: station.point,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showStation(station),
          child: const Icon(
            Icons.ev_station,
            size: 38,
            color: Colors.deepOrange,
          ),
        ),
      );
    }).toList();
  }

  void _showStation(_EvStation station) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.ev_station,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                station.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${station.distanceKm.toStringAsFixed(2)} km away',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${station.point.latitude.toStringAsFixed(5)}, '
                    'Lng: ${station.point.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EV Charging',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              if (currentLocation != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last known location: '
                      '${currentLocation!.latitude.toStringAsFixed(5)}, '
                      '${currentLocation!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEvStations,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: currentLocation!,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.roadwise',
            ),

            // Your current location — bright blue so it never blends
            // into the map tiles.
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    size: 50,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            // Nearby EV charging stations.
            MarkerLayer(
              markers: stationMarkers,
            ),
          ],
        ),

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(Icons.ev_station),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stationMarkers.isEmpty
                              ? 'No stations within $_lastSearchRadiusKm km'
                              : '${stationMarkers.length} charging stations within $_lastSearchRadiusKm km',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (currentLocation != null)
                          Text(
                            'Lat: ${currentLocation!.latitude.toStringAsFixed(5)}, '
                                'Lng: ${currentLocation!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        if (stations.isNotEmpty)
                          Text(
                            'Nearest: ${stations.first.name} '
                                '(${stations.first.distanceKm.toStringAsFixed(2)} km)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadEvStations,
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable list of nearby stations with distances, so you don't
        // have to tap every marker to see how far each one is.
        if (stations.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final station = stations[index];
                  return GestureDetector(
                    onTap: () => _showStation(station),
                    child: Card(
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${station.distanceKm.toStringAsFixed(2)} km away',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}