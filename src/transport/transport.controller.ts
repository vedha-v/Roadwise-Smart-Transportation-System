import { Controller, Get } from '@nestjs/common';

@Controller('transport')
export class TransportController {

  @Get()
  getTransport() {
    return "Transport API working";
  }

}


