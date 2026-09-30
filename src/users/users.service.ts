import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';

export interface User {
  id: number;
  name: string;
  email: string;
  role: string;
}

@Injectable()
export class UsersService {
  private users: User[] = [];

  private nextUserId = 1;

  createUser(
    name: string,
    email: string,
    role: string = 'User',
  ) {
    const existingUser =
      this.users.find(
        (user) =>
          user.email === email,
      );

    if (existingUser) {
      return {
        message:
          'User with this email already exists',
      };
    }

    const newUser: User = {
      id: this.nextUserId++,
      name,
      email,
      role,
    };

    this.users.push(newUser);

    return {
      user: newUser,
      message:
        'User created successfully',
    };
  }

  getAllUsers() {
    return {
      users: this.users,
      message:
        'Users data available',
    };
  }

  getUserById(id: number) {
    const user =
      this.users.find(
        (user) =>
          user.id === id,
      );

    if (!user) {
      throw new NotFoundException(
        'User not found',
      );
    }

    return {
      user,
      message:
        'User found',
    };
  }
}