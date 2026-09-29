import { Controller, Get, Post, Body } from '@nestjs/common';


@Controller('bookings')
export class BookingsController {


  private bookings = [

    {
      bookingId: "BK1001",
      userId: 1,
      parking: "City Parking",
      slot: "A12",
      duration: 2,
      status: "Confirmed"
    }

  ];



  @Get()
  getBookings(){

    return {

      bookings: this.bookings,

      message: "Bookings available"

    };

  }



  @Post()
  createBooking(
    @Body() bookingData:any
  ){

    const newBooking = {

      bookingId:
        "BK" + (1000 + this.bookings.length + 1),

      userId:
        bookingData.userId,

      parking:
        bookingData.parking,

      slot:
        bookingData.slot,

      duration:
        bookingData.duration,

      status:
        "Confirmed"

    };


    this.bookings.push(newBooking);


    return {

      booking:newBooking,

      message:"Booking created successfully"

    };

  }


}