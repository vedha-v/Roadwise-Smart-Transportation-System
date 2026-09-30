import { Controller, Get } from '@nestjs/common';
import { pool } from '../database/database';

@Controller('users')
export class UsersController {
  @Get()
  async getUsers() {
    const result = await pool.query(
      `SELECT id, name, email, role
       FROM users
       ORDER BY id ASC`,
    );

    return {
      users: result.rows,
      message: 'Users data available',
    };
  }
}