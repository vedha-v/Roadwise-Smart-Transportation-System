import {
  BadRequestException,
  Body,
  ConflictException,
  Controller,
  HttpCode,
  Post,
  UnauthorizedException,
} from '@nestjs/common';

type AuthUser = {
  id: number;
  name: string;
  email: string;
  password: string;
};

@Controller('auth')
export class AuthController {
  private readonly users: AuthUser[] = [];

  @Post('register')
  register(@Body() userData: Partial<AuthUser>) {
    const name = userData.name?.trim();
    const email = userData.email?.trim().toLowerCase();
    const password = userData.password;
    if (!name || !email || !password) {
      throw new BadRequestException('Name, email, and password are required');
    }
    if (this.users.some((user) => user.email === email)) {
      throw new ConflictException('An account with this email already exists');
    }
    const newUser = {
      id: this.users.length + 1,
      name,
      email,
      password,
    };
    this.users.push(newUser);
    return {
      userId: newUser.id,
      name: newUser.name,
      email: newUser.email,
      message: 'User registered successfully',
    };
  }

  @HttpCode(200)
  @Post('login')
  login(@Body() loginData: Pick<AuthUser, 'email' | 'password'>) {
    const email = loginData.email?.trim().toLowerCase();
    const user = this.users.find(
      (u) =>
        u.email === email &&
        u.password === loginData.password,
    );

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return {
      userId: user.id,
      name: user.name,
      email: user.email,
      message: 'Login successful',
    };
  }
}