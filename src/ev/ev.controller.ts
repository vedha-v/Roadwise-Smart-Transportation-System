import { Controller, Get } from '@nestjs/common';


@Controller('ev')
export class EvController {


  @Get()
  getEVStations(){

    return {

      stations: [

        {
          id: 1,
          name: "Green Charge Station",
          location: "MG Road",
          chargingType: "Fast Charging",
          availableChargers: 5,
          totalChargers: 10,
          status: "Available",
          distance: "1 km"
        },


        {
          id: 2,
          name: "Eco Power Hub",
          location: "Central Mall",
          chargingType: "Normal Charging",
          availableChargers: 3,
          totalChargers: 8,
          status: "Available",
          distance: "2 km"
        },


        {
          id: 3,
          name: "Airport EV Station",
          location: "Airport Road",
          chargingType: "Fast Charging",
          availableChargers: 8,
          totalChargers: 12,
          status: "Available",
          distance: "4 km"
        }

      ],

      message: "EV stations available"

    };

  }

}