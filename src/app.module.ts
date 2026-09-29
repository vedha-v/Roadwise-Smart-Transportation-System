import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { createObserveModule } from '@nestjs/observe';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TrafficModule } from './traffic/traffic.module';
import { TransportModule } from './transport/transport.module';
import { EvModule } from './ev/ev.module';
import { ParkingModule } from './parking/parking.module';
import { BookingsModule } from './bookings/bookings.module';
import { RouteModule } from './route/route.module';

export const { ObserveModule, ObserveInstrument } =
  createObserveModule();

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    ObserveModule.forRootAsync({
      imports: [ConfigModule],

      inject: [ConfigService],

      useFactory: (config: ConfigService) => ({
        appKey: config.getOrThrow<string>('OBSERVE_APP_KEY'),

        appSecret: config.getOrThrow<string>(
          'OBSERVE_APP_SECRET',
        ),

        serviceId: config.get<string>(
          'SERVICE_ID',
          'roadwise-backend',
        ),
      }),
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