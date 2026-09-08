import 'dart:convert';

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

class _EvPageState extends State<EvPage> {
  LatLng? currentLocation;
  List<Marker> stationMarkers = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvStations();
  }

  Future<void> _loadEvStations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final position = await _getLocation();

      if (position == null) {
        return;
      }

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentLocation = location;
      });

      await _findNearbyStations(location);
    } catch (e) {
      setState(() {
        errorMessage = 'Could not load EV charging stations.';
        isLoading = false;
      });
    }
  }

  Future<Position?> _getLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Location services are disabled.';
        isLoading = false;
      });
      return null;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

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
        errorMessage =
            'Location permission is permanently denied.';
        isLoading = false;
      });
      return null;
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _findNearbyStations(LatLng location) async {
    const radius = 5000;

    final query = '''
[out:json];
(
  node["amenity"="charging_station"]
    (around:$radius,${location.latitude},${location.longitude});

  way["amenity"="charging_station"]
    (around:$radius,${location.latitude},${location.longitude});
);
out center;
''';

    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter',
    );

    final response = await http.post(
      url,
      body: {
        'data': query,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Overpass API request failed');
    }

    final data = jsonDecode(response.body);

    final List elements = data['elements'];

    final markers = <Marker>[];

    for (final element in elements) {
      double? latitude;
      double? longitude;

      if (element['type'] == 'node') {
        latitude = (element['lat'] as num).toDouble();
        longitude = (element['lon'] as num).toDouble();
      } else if (element['center'] != null) {
        latitude =
            (element['center']['lat'] as num).toDouble();
        longitude =
            (element['center']['lon'] as num).toDouble();
      }

      if (latitude == null || longitude == null) {
        continue;
      }

      final tags = element['tags'] ?? {};
      final name = tags['name'] ?? 'EV Charging Station';

      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              _showStation(name);
            },
            child: const Icon(
              Icons.ev_station,
              size: 38,
            ),
          ),
        ),
      );
    }

    setState(() {
      stationMarkers = markers;
      isLoading = false;
    });
  }

  void _showStation(String name) {
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
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'EV charging station',
                style: TextStyle(fontSize: 16),
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
              ),
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
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.roadwise',
            ),

            // Your current location.
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    size: 50,
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
                    child: Text(
                      '${stationMarkers.length} charging stations nearby',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
      ],
    );
  }
}