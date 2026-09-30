import { Module } from '@nestjs/common';

import { ExploreController } from './explore.controller';
import { ExploreService } from './explore.service';
import { OverpassService } from './overpass.service';

@Module({
  controllers: [ExploreController],

  providers: [
    ExploreService,
    OverpassService,
  ],

  exports: [
    ExploreService,
  ],
})
export class ExploreModule {}