import {
  Body,
  Controller,
  Post,
} from '@nestjs/common';

import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
  ) {}

  @Post('register')
  async register(
    @Body()
    userData: {
      name: string;
      email: string;
      password: string;
    },
  ) {
    return this.authService.register(
      userData.name,
      userData.email,
      userData.password,
    );
  }

  @Post('login')
  async login(
    @Body()
    loginData: {
      email: string;
      password: string;
    },
  ) {
    return this.authService.login(
      loginData.email,
      loginData.password,
    );
  }
}