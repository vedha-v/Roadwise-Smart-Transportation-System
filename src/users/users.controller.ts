import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
} from '@nestjs/common';

import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
  ) {}

  @Post()
  createUser(
    @Body()
    userData: {
      name: string;
      email: string;
      role?: string;
    },
  ) {
    if (
      !userData.name ||
      !userData.email
    ) {
      throw new BadRequestException(
        'Name and email are required',
      );
    }

    return this.usersService.createUser(
      userData.name,
      userData.email,
      userData.role,
    );
  }

  @Get()
  getAllUsers() {
    return this.usersService.getAllUsers();
  }

  @Get(':id')
  getUserById(
    @Param('id') id: string,
  ) {
    const userId = Number(id);

    if (!Number.isInteger(userId)) {
      throw new BadRequestException(
        'User ID must be a valid number',
      );
    }

    return this.usersService.getUserById(
      userId,
    );
  }
}