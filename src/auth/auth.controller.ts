import {
  Body,
  ConflictException,
  Controller,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { pool } from '../database/database';

@Controller('auth')
export class AuthController {
  @Post('register')
  async register(@Body() userData: any) {
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [userData.email],
    );

    if (existingUser.rows.length > 0) {
      throw new ConflictException('Email already registered');
    }

    const result = await pool.query(
      `INSERT INTO users (name, email, password)
       VALUES ($1, $2, $3)
       RETURNING id, name, email, role`,
      [
        userData.name,
        userData.email,
        userData.password,
      ],
    );

    return {
      userId: result.rows[0].id,
      name: result.rows[0].name,
      email: result.rows[0].email,
      role: result.rows[0].role,
      message: 'User registered successfully',
    };
  }

  @Post('login')
  async login(@Body() loginData: any) {
    const result = await pool.query(
      `SELECT id, name, email, password, role
       FROM users
       WHERE email = $1`,
      [loginData.email],
    );

    if (result.rows.length === 0) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const user = result.rows[0];

    if (user.password !== loginData.password) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    return {
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      message: 'Login successful',
    };
  }
}