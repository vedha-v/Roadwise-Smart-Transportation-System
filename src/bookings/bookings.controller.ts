import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ParkingService } from '../parking/parking.service';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly parkingService: ParkingService) {}

  @Get()
  getBookings(@Query('userId') userId?: string) {
    return this.parkingService.getReservations(userId);
  }

  @Post()
  createBooking(@Body() bookingData: {
    userId?: string;
    slotId?: number;
    startsAt?: string;
    endsAt?: string;
  }) {
    return this.parkingService.createReservation(bookingData);
  }
}