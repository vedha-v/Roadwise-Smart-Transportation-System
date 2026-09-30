import {
  BadRequestException,
  Controller,
  Get,
  Query,
} from '@nestjs/common';

import { ExploreService } from './explore.service';

@Controller('explore')
export class ExploreController {
  constructor(
    private readonly exploreService: ExploreService,
  ) {}

  @Get('nearby')
  async getNearbyLocations(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('vehicle') vehicle: string,
  ) {
    const latitude = Number(lat);
    const longitude = Number(lng);

    if (
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude)
    ) {
      throw new BadRequestException(
        'Valid latitude and longitude are required',
      );
    }

    if (
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180
    ) {
      throw new BadRequestException(
        'Latitude or longitude is outside the valid range',
      );
    }

    if (!vehicle) {
      throw new BadRequestException(
        'Vehicle type is required',
      );
    }

    return this.exploreService.getNearbyLocations(
      latitude,
      longitude,
      vehicle,
    );
  }
}