import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import * as bcrypt from 'bcrypt';

import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  private users: any[] = [];

  constructor(
    private readonly jwtService: JwtService,
  ) {}

  async register(
    name: string,
    email: string,
    password: string,
  ) {
    const existingUser =
      this.users.find(
        (user) =>
          user.email === email,
      );

    if (existingUser) {
      throw new ConflictException(
        'Email already registered',
      );
    }

    const hashedPassword =
      await bcrypt.hash(
        password,
        10,
      );

    const newUser = {
      id:
        this.users.length + 1,

      name,

      email,

      password:
        hashedPassword,
    };

    this.users.push(newUser);

    return {
      userId: newUser.id,
      name: newUser.name,
      email: newUser.email,
      message:
        'User registered successfully',
    };
  }

  async login(
    email: string,
    password: string,
  ) {
    const user =
      this.users.find(
        (u) =>
          u.email === email,
      );

    if (!user) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const passwordMatches =
      await bcrypt.compare(
        password,
        user.password,
      );

    if (!passwordMatches) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const payload = {
      sub: user.id,
      email: user.email,
    };

    const accessToken =
      await this.jwtService.signAsync(
        payload,
      );

    return {
      userId: user.id,
      name: user.name,
      email: user.email,
      accessToken,
      message:
        'Login successful',
    };
  }
}