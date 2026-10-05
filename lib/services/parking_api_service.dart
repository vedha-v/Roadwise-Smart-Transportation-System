import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'api_config.dart';

class ParkingFacility {
  final String osmType;
  final String osmId;
  final String name;
  final LatLng location;
  final double distanceKm;
  final int verifiedSlotCount;
  final bool isDemo;

  const ParkingFacility({
    required this.osmType,
    required this.osmId,
    required this.name,
    required this.location,
    required this.distanceKm,
    required this.verifiedSlotCount,
    required this.isDemo,
  });

  factory ParkingFacility.fromJson(Map<String, dynamic> json) {
    return ParkingFacility(
      osmType: json['osmType'] as String,
      osmId: json['osmId'].toString(),
      name: json['name'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      verifiedSlotCount: json['verifiedSlotCount'] as int,
      isDemo: json['isDemo'] == true,
    );
  }
}

class ParkingSlot {
  final int id;
  final String slotCode;

  const ParkingSlot({required this.id, required this.slotCode});

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      id: int.parse(json['id'].toString()),
      slotCode: json['slotCode'] as String,
    );
  }
}

class ParkingReservation {
  final String bookingId;
  final String parkingName;
  final String slot;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final bool isDemo;

  const ParkingReservation({
    required this.bookingId,
    required this.parkingName,
    required this.slot,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.isDemo,
  });

  factory ParkingReservation.fromJson(Map<String, dynamic> json) {
    return ParkingReservation(
      bookingId: json['bookingId'].toString(),
      parkingName: json['parkingName'] as String,
      slot: json['slot'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: json['status'] as String,
      isDemo: json['osmType'] == 'demo',
    );
  }
}

class ParkingApiService {
  static const userId = 'demo-user';

  Future<List<ParkingFacility>> getNearbyParking() async {
    final data = await _get('/parking?radius=5000');
    return (data['facilities'] as List<dynamic>)
        .map((item) => ParkingFacility.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParkingSlot>> getAvailableSlots(
    ParkingFacility facility,
    DateTime startsAt,
    DateTime endsAt,
  ) async {
    final query = <String, String>{
      'osmType': facility.osmType,
      'osmId': facility.osmId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    };
    final data = await _get(
      '/parking/slots?${Uri(queryParameters: query).query}',
    );
    return (data['slots'] as List<dynamic>)
        .map((item) => ParkingSlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createReservation(
    int slotId,
    DateTime startsAt,
    DateTime endsAt,
  ) async {
    await _send('POST', '/bookings', {
      'userId': userId,
      'slotId': slotId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    });
  }

  Future<List<ParkingReservation>> getReservations() async {
    final data = await _get('/bookings?userId=$userId');
    return (data['bookings'] as List<dynamic>)
        .map(
          (item) => ParkingReservation.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, dynamic>> _get(String path) async {
    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse('$roadwiseApiBaseUrl$path'))
          .timeout(const Duration(seconds: 25));
    } on Exception catch (error) {
      throw Exception(
        'Cannot reach the RoadWise backend at $roadwiseApiBaseUrl. '
        'Start the NestJS server and PostgreSQL. Details: $error',
      );
    }
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$roadwiseApiBaseUrl$path');
    final response = method == 'POST'
        ? await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
        : await http.put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw Exception(
        message ?? 'Parking service returned ${response.statusCode}',
      );
    }
    return decoded as Map<String, dynamic>;
  }
}
