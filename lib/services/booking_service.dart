import 'parking_api_service.dart';

class BookingService {
  static final ParkingApiService _api = ParkingApiService();

  static Future<void> createBooking({
    required int slotId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    return _api.createReservation(slotId, startsAt, endsAt);
  }

  static Future<List<ParkingReservation>> fetchBookings() {
    return _api.getReservations();
  }
}
