import { Module } from '@nestjs/common';

import { EvController } from './ev.controller';
import { EvService } from './ev.service';
import { EvOverpassService } from './ev-overpass.service';

@Module({
  controllers: [EvController],

  providers: [
    EvService,
    EvOverpassService,
  ],

  exports: [
    EvService,
  ],
})
export class EvModule {}