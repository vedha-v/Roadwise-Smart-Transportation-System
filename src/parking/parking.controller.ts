import { Controller, Get } from '@nestjs/common';
import { pool } from '../database/database';

@Controller('parking')
export class ParkingController {
  @Get()
  async getParking() {
    const result = await pool.query(
      'SELECT * FROM parking ORDER BY id ASC',
    );

    return {
      parkingSlots: result.rows,
      message: 'Parking data available',
    };
  }
}