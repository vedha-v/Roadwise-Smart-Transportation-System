import { Module } from '@nestjs/common';
import { ParkingController } from './parking.controller';


@Module({

  controllers: [
    ParkingController
  ]

})

export class ParkingModule {}