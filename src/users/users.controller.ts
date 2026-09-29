import { Controller, Get } from '@nestjs/common';

@Controller('users')
export class UsersController {

  private users = [
    {
      id: 1,
      name: 'Shreya',
      email: 'shreya@gmail.com',
      role: 'User',
    },
  ];

  @Get()
  getUsers() {
    return {
      users: this.users,
      message: 'Users data available',
    };
  }
}
