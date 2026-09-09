// lib/models/parking_booking.dart
class ParkingBooking {
  final String parkingName;
  final String slot;
  final String price;
  final String bookingId;
  final String distance;
  final DateTime bookedAt;

  ParkingBooking({
    required this.parkingName,
    required this.slot,
    required this.price,
    required this.bookingId,
    required this.distance,
    required this.bookedAt,
  });
}