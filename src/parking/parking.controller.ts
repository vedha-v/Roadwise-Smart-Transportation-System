import { Controller, Get } from '@nestjs/common';


@Controller('parking')
export class ParkingController {


  @Get()
  getParking() {

    return {

      parkingSlots: [

        {
          id: 1,
          name: "City Parking",
          location: "MG Road",
          availableSlots: 25,
          totalSlots: 50,
          pricePerHour: 50,
          distance: "0.5 km"
        },


        {
          id: 2,
          name: "Central Mall Parking",
          location: "Central Mall",
          availableSlots: 10,
          totalSlots: 30,
          pricePerHour: 70,
          distance: "1.2 km"
        },


        {
          id: 3,
          name: "Airport Parking",
          location: "Airport Road",
          availableSlots: 40,
          totalSlots: 80,
          pricePerHour: 100,
          distance: "3 km"
        }

      ],

      message: "Parking data available"

    };

  }

}