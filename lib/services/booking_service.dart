import 'parking_api_service.dart';

class BookingService {
  static final ParkingApiService _api = ParkingApiService();

  static Future<List<ParkingReservation>> getBookings() {
    return _api.getReservations();
  }
}
