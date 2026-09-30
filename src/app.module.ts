import { Module } from '@nestjs/common';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TrafficModule } from './traffic/traffic.module';
import { TransportModule } from './transport/transport.module';
import { EvModule } from './ev/ev.module';
import { ParkingModule } from './parking/parking.module';
import { BookingsModule } from './bookings/bookings.module';

import { ExploreModule } from './explore/explore.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    TrafficModule,
    TransportModule,
    EvModule,
    ParkingModule,
    BookingsModule,
    
    ExploreModule,
  ],
})
export class AppModule {}