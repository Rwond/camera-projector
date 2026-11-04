import { Controller, Get, HttpException, HttpStatus } from '@nestjs/common';
import { HealthService } from './health.service.js';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  liveness() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  @Get('db')
  async readiness() {
    const result = await this.healthService.checkDatabase();
    if (result.status === 'error') {
      throw new HttpException(result, HttpStatus.SERVICE_UNAVAILABLE);
    }
    return result;
  }
}
