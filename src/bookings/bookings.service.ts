import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';

import * as QRCode from 'qrcode';

import { bookings, Booking } from './booking.data';
import { parkingData } from '../parking/parking.data';

@Injectable()
export class BookingsService {

  getBookings() {
    return {
      bookings: bookings,
      message: 'Bookings available',
    };
  }

  async createBooking(bookingData: any) {

    const parking = parkingData.find(
      (item) =>
        item.id === Number(bookingData.parkingId),
    );

    if (!parking) {
      throw new NotFoundException(
        'Parking location not found',
      );
    }

    const userId = Number(bookingData.userId);
    const duration = Number(bookingData.duration);

    if (!userId) {
      throw new BadRequestException(
        'User ID is required',
      );
    }

    if (!duration || duration <= 0) {
      throw new BadRequestException(
        'Booking duration must be greater than 0',
      );
    }

    if (parking.availableSlots <= 0) {
      throw new BadRequestException(
        'No parking slots available',
      );
    }

    const amount =
      parking.pricePerHour * duration;

    const bookingId =
      `BK${1000 + bookings.length + 1}`;

    const bookingCode =
      `ROADWISE-${bookingId}`;

    const slotNumber =
      `SLOT-${parking.availableSlots}`;

    // Generate QR code containing the booking code
    const qrCode =
      await QRCode.toDataURL(bookingCode);

    const newBooking: Booking = {
      bookingId: bookingId,
      userId: userId,
      parkingId: parking.id,
      parkingName: parking.name,
      location: parking.location,
      slotNumber: slotNumber,
      duration: duration,
      amount: amount,
      status: 'Confirmed',
      bookingCode: bookingCode,
      qrCode: qrCode,
      createdAt: new Date().toISOString(),
    };

    bookings.push(newBooking);

    parking.availableSlots--;

    return {
      booking: newBooking,
      message: 'Parking booked successfully',
    };
  }

  getBookingById(bookingId: string) {

    const booking = bookings.find(
      (item: Booking) =>
        item.bookingId === bookingId,
    );

    if (!booking) {
      throw new NotFoundException(
        'Booking not found',
      );
    }

    return {
      booking: booking,
      message: 'Booking found',
    };
  }

  scanBooking(bookingCode: string) {

    const booking = bookings.find(
      (item: Booking) =>
        item.bookingCode === bookingCode,
    );

    if (!booking) {
      throw new NotFoundException(
        'Invalid booking code',
      );
    }

    return {
      valid: true,
      booking: booking,
      message: 'Booking verified successfully',
    };
  }
}