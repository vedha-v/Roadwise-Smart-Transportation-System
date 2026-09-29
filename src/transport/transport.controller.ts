import { Controller, Get } from '@nestjs/common';

@Controller('transport')
export class TransportController {


  @Get()
  getTransport() {

    return {

      traffic: "Moderate",

      availableTransport: [
        "Car",
        "Bus",
        "Train",
        "Public Transport",
        "Two Wheeler",
        "Freight Vehicle"
      ],

      destinations: [
        "Airport",
        "Railway Station",
        "Shopping Mall",
        "University"
      ],

      message: "Transport services available"

    };

  }


}