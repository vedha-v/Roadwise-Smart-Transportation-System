import { Module } from '@nestjs/common';
import { TrafficController } from './traffic.controller';

@Module({
  controllers: [TrafficController],
})
export class TrafficModule {}