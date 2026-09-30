import {
  Body,
  Controller,
  Get,
  Param,
  Post,
} from '@nestjs/common';

import { BookingsService } from './bookings.service';

@Controller('bookings')
export class BookingsController {

  constructor(
    private readonly bookingsService: BookingsService,
  ) {}

  @Get()
  getBookings() {
    return this.bookingsService.getBookings();
  }

  @Post()
  createBooking(
    @Body() bookingData: any,
  ) {
    return this.bookingsService.createBooking(
      bookingData,
    );
  }

  @Get(':bookingId')
  getBookingById(
    @Param('bookingId') bookingId: string,
  ) {
    return this.bookingsService.getBookingById(
      bookingId,
    );
  }

  @Post('scan')
  scanBooking(
    @Body() scanData: any,
  ) {
    return this.bookingsService.scanBooking(
      scanData.bookingCode,
    );
  }
}