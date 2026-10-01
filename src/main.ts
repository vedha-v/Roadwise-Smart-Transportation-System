import { NestFactory } from '@nestjs/core';
import {
  AppModule,
  isObserveConfigured,
  ObserveInstrument,
} from './app.module';

async function bootstrap() {
  try {
    const app = await NestFactory.create(
      AppModule,
      isObserveConfigured() ? { instrument: ObserveInstrument } : {},
    );

    app.enableCors({
      origin: true,
      methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
      credentials: true,
    });

    app.setGlobalPrefix('api');

    const port = process.env.PORT || 3000;

    await app.listen(port);

    console.log(`Roadwise Backend running on http://localhost:${port}`);
  } catch (error) {
    console.error('Roadwise Backend failed to start:', error);
    process.exitCode = 1;
  }
}

bootstrap();