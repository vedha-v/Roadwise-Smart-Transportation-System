import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { TrafficService } from './traffic.service';

@Controller('traffic')
export class TrafficController {
  constructor(private readonly trafficService: TrafficService) {}

  @Get()
  getTraffic(
    @Query('latitude') latitude?: string,
    @Query('longitude') longitude?: string,
    @Query('radius') radius?: string,
  ) {
    const coordinates = [latitude, longitude].map((value) =>
      value === undefined ? undefined : Number(value),
    );
    const [lat, lon] = coordinates;
    const radiusMeters = radius === undefined ? 3000 : Number(radius);
    if (
      (lat !== undefined && (!Number.isFinite(lat) || lat < -90 || lat > 90)) ||
      (lon !== undefined && (!Number.isFinite(lon) || lon < -180 || lon > 180)) ||
      (lat === undefined) !== (lon === undefined) ||
      !Number.isInteger(radiusMeters) || radiusMeters < 500 || radiusMeters > 10000
    ) {
      throw new BadRequestException(
        'Provide valid latitude and longitude together; radius must be 500-10000 meters',
      );
    }
    return this.trafficService.getTraffic(lat, lon, radiusMeters);
  }
}