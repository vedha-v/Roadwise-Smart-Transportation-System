import {
  Body,
  ConflictException,
  Controller,
  Get,
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

  @Post()
  async createBooking(@Body() bookingData: any) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Lock the parking row while we check/update availability
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

      // Reduce available slots by 1
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

      // PostgreSQL unique constraint violation
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
}