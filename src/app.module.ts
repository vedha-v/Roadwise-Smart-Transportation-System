import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';


import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TrafficModule } from './traffic/traffic.module';
import { TransportModule } from './transport/transport.module';
import { EvModule } from './ev/ev.module';
import { ParkingModule } from './parking/parking.module';
import { BookingsModule } from './bookings/bookings.module';
import { RouteModule } from './route/route.module';


@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),


    AuthModule,
    UsersModule,
    TrafficModule,
    TransportModule,
    EvModule,
    ParkingModule,
    BookingsModule,
    RouteModule,
  ],
})
export class AppModule {}