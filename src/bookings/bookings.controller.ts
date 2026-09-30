import { Body, Controller, Get, Post } from '@nestjs/common';
import { pool } from '../database/database';

@Controller('bookings')
export class BookingsController {
  @Get()
  async getBookings() {
    const result = await pool.query(
      'SELECT * FROM bookings ORDER BY id DESC',
    );

    return {
      bookings: result.rows,
      message: 'Bookings available',
    };
  }

  @Post()
  async createBooking(@Body() bookingData: any) {
    const bookingId =
      'BK' + Date.now();

    const result = await pool.query(
      `INSERT INTO bookings
      (booking_id, user_id, parking, slot, duration, status)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *`,
      [
        bookingId,
        bookingData.userId,
        bookingData.parking,
        bookingData.slot,
        bookingData.duration,
        'Confirmed',
      ],
    );

    return {
      booking: result.rows[0],
      message: 'Booking created successfully',
    };
  }
}