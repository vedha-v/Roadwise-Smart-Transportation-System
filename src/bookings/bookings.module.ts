import { Module } from '@nestjs/common';
import { BookingsController } from './bookings.controller';
import { ParkingModule } from '../parking/parking.module';


@Module({
 imports: [ParkingModule],

 controllers:[
   BookingsController
 ]

})

export class BookingsModule {}