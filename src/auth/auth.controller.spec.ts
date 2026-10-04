import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { AuthController } from './auth.controller';

describe('AuthController', () => {
  it('registers a user and logs in with normalized email', () => {
    const controller = new AuthController();
    controller.register({
      name: 'RoadWise User',
      email: 'Demo@RoadWise.com',
      password: 'roadwise123',
    });

    expect(
      controller.login({
        email: 'demo@roadwise.com',
        password: 'roadwise123',
      }),
    ).toMatchObject({
      userId: 1,
      name: 'RoadWise User',
      email: 'demo@roadwise.com',
    });
  });

  it('rejects invalid credentials and duplicate accounts', () => {
    const controller = new AuthController();
    controller.register({
      name: 'RoadWise User',
      email: 'demo@roadwise.com',
      password: 'roadwise123',
    });

    expect(() =>
      controller.login({
        email: 'demo@roadwise.com',
        password: 'incorrect',
      }),
    ).toThrow(UnauthorizedException);
    expect(() =>
      controller.register({
        name: 'Another User',
        email: 'DEMO@ROADWISE.COM',
        password: 'other-password',
      }),
    ).toThrow(ConflictException);
  });
});