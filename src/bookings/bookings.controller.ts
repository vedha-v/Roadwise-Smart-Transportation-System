import {
  Body,
  ConflictException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
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

  @Get(':bookingId')
  async getBookingById(
    @Param('bookingId') bookingId: string,
  ) {
    const result = await pool.query(
      'SELECT * FROM bookings WHERE booking_id = $1',
      [bookingId],
    );

    if (result.rows.length === 0) {
      throw new NotFoundException('Booking not found');
    }

    return {
      booking: result.rows[0],
      message: 'Booking found',
    };
  }

  @Post()
  async createBooking(@Body() bookingData: any) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const parkingResult = await client.query(
        'SELECT * FROM parking WHERE name = $1 FOR UPDATE',
        [bookingData.parking],
      );

      if (parkingResult.rows.length === 0) {
        throw new ConflictException('Parking location not found');
      }

      const parking = parkingResult.rows[0];

      if (parking.available_slots <= 0) {
        throw new ConflictException(
          'No parking slots are currently available',
        );
      }

      const bookingId = 'BK' + Date.now();

      const result = await client.query(
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

      await client.query(
        `UPDATE parking
         SET available_slots = available_slots - 1
         WHERE name = $1`,
        [bookingData.parking],
      );

      await client.query('COMMIT');

      return {
        booking: result.rows[0],
        message: 'Booking created successfully',
      };
    } catch (error: any) {
      await client.query('ROLLBACK');

      if (error.code === '23505') {
        throw new ConflictException(
          'This parking slot is already booked',
        );
      }

      throw error;
    } finally {
      client.release();
    }
  }

  @Patch(':bookingId/cancel')
  async cancelBooking(
    @Param('bookingId') bookingId: string,
  ) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const bookingResult = await client.query(
        `SELECT * FROM bookings
         WHERE booking_id = $1
         FOR UPDATE`,
        [bookingId],
      );

      if (bookingResult.rows.length === 0) {
        throw new NotFoundException('Booking not found');
      }

      const booking = bookingResult.rows[0];

      if (booking.status !== 'Confirmed') {
        throw new ConflictException(
          'This booking is already cancelled',
        );
      }

      await client.query(
        `UPDATE bookings
         SET status = 'Cancelled'
         WHERE booking_id = $1`,
        [bookingId],
      );

      await client.query(
        `UPDATE parking
         SET available_slots = LEAST(total_slots, available_slots + 1)
         WHERE name = $1`,
        [booking.parking],
      );

      await client.query('COMMIT');

      return {
        bookingId,
        status: 'Cancelled',
        message: 'Booking cancelled successfully',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}