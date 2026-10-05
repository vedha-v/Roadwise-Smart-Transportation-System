import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'traffic_api_service.dart';

class FreightRoutePlan {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const FreightRoutePlan({
    required this.origin,
    required this.destination,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteTrafficCheck {
  final LatLng point;
  final TrafficSnapshot? snapshot;
  final String? error;

  const RouteTrafficCheck({required this.point, this.snapshot, this.error});
}

class FreightRouteService {
  static const _userAgent = 'RoadWise/1.0 (freight route planner)';
  final TrafficApiService _trafficApi = TrafficApiService();

  Future<FreightRoutePlan> planRoute({
    required String origin,
    required String destination,
  }) async {
    final from = await _geocode(origin);
    // Nominatim's public endpoint allows no more than one request per second.
    await Future<void>.delayed(const Duration(seconds: 1));
    final to = await _geocode(destination);
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    );

    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Route service returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      throw Exception('No driving route was found between those places.');
    }
    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw Exception('Route service returned no route geometry.');
    }
    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometry = route['geometry'];
    if (geometry is! Map || geometry['coordinates'] is! List) {
      throw Exception('Route service returned invalid route geometry.');
    }
    final points = (geometry['coordinates'] as List)
        .whereType<List>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    if (points.length < 2) {
      throw Exception('Route service returned an incomplete route.');
    }

    return FreightRoutePlan(
      origin: from,
      destination: to,
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  Future<List<RouteTrafficCheck>> checkTrafficAlongRoute(
    List<LatLng> routePoints,
  ) async {
    final samplePoints = _sampleRoute(routePoints);
    return Future.wait(
      samplePoints.map((point) async {
        try {
          final snapshot = await _trafficApi.getTraffic(
            latitude: point.latitude,
            longitude: point.longitude,
          );
          return RouteTrafficCheck(point: point, snapshot: snapshot);
        } catch (error) {
          return RouteTrafficCheck(
            point: point,
            error: error.toString().replaceFirst('Exception: ', ''),
          );
        }
      }),
    );
  }

  Future<LatLng> _geocode(String place) async {
    final query = place.trim();
    if (query.isEmpty) {
      throw Exception('Enter both a starting point and a destination.');
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
    });
    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Place search returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
      throw Exception('Could not find "$query". Try a city or full address.');
    }
    final result = Map<String, dynamic>.from(decoded.first as Map);
    final latitude = double.tryParse(result['lat']?.toString() ?? '');
    final longitude = double.tryParse(result['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      throw Exception(
        'Place search returned invalid coordinates for "$query".',
      );
    }
    return LatLng(latitude, longitude);
  }

  List<LatLng> _sampleRoute(List<LatLng> points) {
    const sampleCount = 5;
    if (points.length <= sampleCount) return points;

    return List.generate(sampleCount, (index) {
      final routeIndex = (index * (points.length - 1) / (sampleCount - 1))
          .round();
      return points[routeIndex];
    });
  }
}
