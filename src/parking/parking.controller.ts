import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  UnauthorizedException,
  Post,
  Query,
} from '@nestjs/common';
import { ParkingService } from './parking.service';

@Controller('parking')
export class ParkingController {
  constructor(private readonly parkingService: ParkingService) {}

  @Get()
  getNearbyParking(@Query('radius') radius?: string) {
    const radiusMeters = radius === undefined ? 5000 : Number(radius);
    if (!Number.isInteger(radiusMeters) || radiusMeters < 100 || radiusMeters > 30000) {
      throw new BadRequestException('radius must be between 100 and 30000 meters');
    }
    return this.parkingService.getNearbyParking(radiusMeters);
  }

  @Get('slots')
  getAvailableSlots(
    @Query('osmType') osmType: string,
    @Query('osmId') osmId: string,
    @Query('startsAt') startsAt: string,
    @Query('endsAt') endsAt: string,
  ) {
    return this.parkingService.getAvailableSlots({ osmType, osmId, startsAt, endsAt });
  }

  @Post('inventory')
  addVerifiedInventory(
    @Body() body: { osmType?: string; osmId?: string; slots?: string[]; verifiedBy?: string },
    @Headers('x-parking-admin-token') token: string,
  ) {
    if (!process.env.PARKING_ADMIN_TOKEN || token !== process.env.PARKING_ADMIN_TOKEN) {
      throw new UnauthorizedException('A valid parking admin token is required');
    }
    return this.parkingService.addVerifiedInventory(body);
  }
}