import { Body, Controller, Post } from '@nestjs/common';

@Controller('auth')
export class AuthController {

 private users: any[] = [];

  @Post('register')
  register(@Body() userData: any) {

    const newUser = {
      id: this.users.length + 1,
      name: userData.name,
      email: userData.email,
      password: userData.password,
    };

    this.users.push(newUser);

    return {
      userId: newUser.id,
      name: newUser.name,
      email: newUser.email,
      message: 'User registered successfully',
    };
  }


  @Post('login')
  login(@Body() loginData: any) {

    const user = this.users.find(
      (u) =>
        u.email === loginData.email &&
        u.password === loginData.password,
    );

    if (!user) {
      return {
        message: 'Invalid email or password',
      };
    }

    return {
      userId: user.id,
      name: user.name,
      email: user.email,
      message: 'Login successful',
    };
  }
}