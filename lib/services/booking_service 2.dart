//booking service
import '../models/parking_booking.dart';

class BookingService {
  static final List<ParkingBooking> bookings = [];

  static void addBooking(ParkingBooking booking) {
    bookings.insert(0, booking);
  }
}