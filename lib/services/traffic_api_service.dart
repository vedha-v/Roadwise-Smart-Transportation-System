import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class TrafficSnapshot {
  final String source;
  final bool stale;
  final DateTime capturedAt;
  final String status;
  final int congestionPercent;
  final double currentSpeed;
  final double freeFlowSpeed;
  final double confidence;
  final bool roadClosure;
  final List<TrafficCoordinate> segment;
  final List<TrafficIncident> incidents;

  const TrafficSnapshot({
    required this.source,
    required this.stale,
    required this.capturedAt,
    required this.status,
    required this.congestionPercent,
    required this.currentSpeed,
    required this.freeFlowSpeed,
    required this.confidence,
    required this.roadClosure,
    required this.segment,
    required this.incidents,
  });

  factory TrafficSnapshot.fromJson(Map<String, dynamic> json) {
    final flow = Map<String, dynamic>.from(json['flow'] as Map);
    return TrafficSnapshot(
      source: json['source'] as String? ?? 'TomTom Traffic API',
      stale: json['stale'] == true,
      capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
      status: json['status'] as String? ?? 'Unknown',
      congestionPercent: (json['congestionPercent'] as num?)?.toInt() ?? 0,
      currentSpeed: (flow['currentSpeed'] as num?)?.toDouble() ?? 0,
      freeFlowSpeed: (flow['freeFlowSpeed'] as num?)?.toDouble() ?? 0,
      confidence: (flow['confidence'] as num?)?.toDouble() ?? 0,
      roadClosure: flow['roadClosure'] == true,
      segment: (flow['coordinates'] as List<dynamic>? ?? const [])
          .map(
            (item) => TrafficCoordinate.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      incidents: (json['incidents'] as List<dynamic>? ?? const [])
          .map((item) => TrafficIncident.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrafficCoordinate {
  final double latitude;
  final double longitude;

  const TrafficCoordinate({required this.latitude, required this.longitude});

  factory TrafficCoordinate.fromJson(Map<String, dynamic> json) {
    return TrafficCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class TrafficIncident {
  final String id;
  final String type;
  final String severity;
  final String? from;
  final String? to;
  final int delaySeconds;
  final double? latitude;
  final double? longitude;

  const TrafficIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.from,
    required this.to,
    required this.delaySeconds,
    required this.latitude,
    required this.longitude,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    return TrafficIncident(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'Traffic incident',
      severity: json['severity'] as String? ?? 'Unknown',
      from: json['from'] as String?,
      to: json['to'] as String?,
      delaySeconds: (json['delaySeconds'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class TrafficApiService {
  Future<TrafficSnapshot> getTraffic({
    required double latitude,
    required double longitude,
    int radiusMeters = 3000,
  }) async {
    final query = Uri(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radiusMeters.toString(),
      },
    ).query;
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse('$roadwiseApiBaseUrl/traffic?$query'))
          .timeout(const Duration(seconds: 25));
    } on Exception catch (error) {
      throw Exception('Cannot reach the traffic backend. Details: $error');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(
        message ?? 'Traffic service returned ${response.statusCode}',
      );
    }
    return TrafficSnapshot.fromJson(decoded as Map<String, dynamic>);
  }
}
