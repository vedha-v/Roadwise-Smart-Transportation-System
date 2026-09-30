import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parking_booking.dart';

class BookingService {
  static final List<ParkingBooking> bookings = [];

  static const String _backendBaseUrl =
      'http://10.0.2.2:3000/api';

  static void addBooking(ParkingBooking booking) {
    bookings.insert(0, booking);
  }

  static Future<ParkingBooking?> createBooking({
    required int userId,
    required String parkingName,
    required String slot,
    required int duration,
    required String price,
    required String distance,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'parking': parkingName,
          'slot': slot,
          'duration': duration,
        }),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final backendBooking = data['booking'];

      if (backendBooking == null) {
        return null;
      }

      final booking = ParkingBooking(
        parkingName:
            backendBooking['parking']?.toString() ?? parkingName,
        slot: backendBooking['slot']?.toString() ?? slot,
        price: price,
        bookingId:
            backendBooking['bookingId']?.toString() ?? 'BK0000',
        distance: distance,
        bookedAt: DateTime.now(),
      );

      addBooking(booking);

      return booking;
    } catch (e) {
      return null;
    }
  }

  static Future<List<ParkingBooking>> fetchBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/bookings'),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final backendBookings = data['bookings'];

      if (backendBookings is! List) {
        return [];
      }

      var fetchedBookings = backendBookings.map<ParkingBooking>((item) {
        final bookingId =
            item['bookingId']?.toString() ?? 'BK0000';

        // Keep price and distance from the local booking if we
        // already created this booking in the current app session.
        ParkingBooking? existingBooking;

        for (final booking in bookings) {
          if (booking.bookingId == bookingId) {
            existingBooking = booking;
            break;
          }
        }

        return ParkingBooking(
          parkingName:
              item['parking']?.toString() ?? 'Parking',
          slot: item['slot']?.toString() ?? 'Unknown',
          price: existingBooking?.price ?? '—',
          bookingId: bookingId,
          distance: existingBooking?.distance ?? '—',
          bookedAt:
              existingBooking?.bookedAt ?? DateTime.now(),
        );
      }).toList();

      // Keep the newest bookings first.
      fetchedBookings = fetchedBookings.reversed.toList();

      // Keep the local cache synchronized with the backend.
      bookings
        ..clear()
        ..addAll(fetchedBookings);

      return fetchedBookings;
    } catch (e) {
      return [];
    }
  }
}