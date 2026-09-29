import { Controller, Get } from '@nestjs/common';

@Controller('traffic')
export class TrafficController {

  @Get()
  getTraffic() {
    return {
      status: 'Moderate',

      congestionLevel: 55,

      averageSpeed: '35 km/h',

      incidents: [
        {
          id: 1,
          type: 'Accident',
          location: 'MG Road',
          severity: 'Medium',
        },
        {
          id: 2,
          type: 'Road Construction',
          location: 'Airport Road',
          severity: 'Low',
        },
      ],

      roads: [
        {
          name: 'MG Road',
          status: 'Moderate',
          speed: '35 km/h',
        },
        {
          name: 'Airport Road',
          status: 'Heavy',
          speed: '20 km/h',
        },
        {
          name: 'Station Road',
          status: 'Low',
          speed: '45 km/h',
        },
      ],

      message: 'Traffic information available',
    };
  }
}