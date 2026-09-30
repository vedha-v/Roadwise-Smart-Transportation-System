import {
  Controller,
  Get,
  Param,
  Query,
} from '@nestjs/common';

import { ParkingService } from './parking.service';

@Controller('parking')
export class ParkingController {

  constructor(
    private readonly parkingService: ParkingService,
  ) {}

  @Get()
  getAllParking() {
    return this.parkingService.getAllParking();
  }

  @Get('nearby')
  getNearbyParking(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
  ) {
    return this.parkingService.getNearbyParking(
      Number(lat),
      Number(lng),
    );
  }

  @Get(':id')
  getParkingById(
    @Param('id') id: string,
  ) {
    return this.parkingService.getParkingById(
      Number(id),
    );
  }
}