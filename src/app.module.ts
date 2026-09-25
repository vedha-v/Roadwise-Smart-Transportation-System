import { Module } from '@nestjs/common';
import { TransportModule } from './transport/transport.module';

@Module({
  imports: [
    TransportModule,
  ],
})
export class AppModule {}