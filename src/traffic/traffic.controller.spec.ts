import { BadRequestException } from '@nestjs/common';
import { TrafficController } from './traffic.controller';
import { TrafficService } from './traffic.service';

describe('TrafficController', () => {
  const trafficService = {
    getTraffic: vi.fn().mockResolvedValue({ source: 'TomTom Traffic API' }),
  };
  const controller = new TrafficController(trafficService as unknown as TrafficService);

  beforeEach(() => trafficService.getTraffic.mockClear());

  it('leaves default location resolution to the service', async () => {
    await controller.getTraffic();

    expect(trafficService.getTraffic).toHaveBeenCalledWith(undefined, undefined, 3000);
  });

  it('forwards the requested location and radius', async () => {
    await controller.getTraffic('28.6', '77.2', '5000');

    expect(trafficService.getTraffic).toHaveBeenCalledWith(28.6, 77.2, 5000);
  });

  it('rejects partial or invalid coordinates', () => {
    expect(() => controller.getTraffic('28.6')).toThrow(BadRequestException);
    expect(() => controller.getTraffic('91', '77.2')).toThrow(BadRequestException);
    expect(() => controller.getTraffic('28.6', '77.2', '200')).toThrow(
      BadRequestException,
    );
  });
});