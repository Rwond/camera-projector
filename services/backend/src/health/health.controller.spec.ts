import { Test, TestingModule } from '@nestjs/testing';
import { HttpException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { HealthController } from './health.controller.js';
import { HealthService } from './health.service.js';

describe('HealthController', () => {
  let controller: HealthController;
  let healthService: { checkDatabase: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    healthService = { checkDatabase: vi.fn() };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [{ provide: HealthService, useValue: healthService }],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('liveness reports ok without checking dependencies', () => {
    const result = controller.liveness();
    expect(result.status).toBe('ok');
    expect(result.timestamp).toBeDefined();
  });

  it('readiness returns the database check result when healthy', async () => {
    healthService.checkDatabase.mockResolvedValueOnce({ status: 'ok' });

    await expect(controller.readiness()).resolves.toEqual({ status: 'ok' });
  });

  it('readiness throws a 503 when the database check fails', async () => {
    healthService.checkDatabase.mockResolvedValueOnce({ status: 'error', error: 'down' });

    await expect(controller.readiness()).rejects.toBeInstanceOf(HttpException);
  });
});
