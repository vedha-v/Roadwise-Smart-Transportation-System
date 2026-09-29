import { Body, Controller, Post } from '@nestjs/common';

@Controller('route')
export class RouteController {

  @Post('plan')
  planRoute(@Body() routeData: any) {

    const source = routeData.source;
    const destination = routeData.destination;

    return {
      source: source,
      destination: destination,
      distance: '8.5 km',
      estimatedTime: '25 minutes',
      recommendedTransport: 'Public Transport',
      trafficStatus: 'Moderate',
      message: 'Route planned successfully',
    };
  }
}