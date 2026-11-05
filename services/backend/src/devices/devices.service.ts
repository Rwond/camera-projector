import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { Device } from '../generated/prisma/client.js';
import type { RegisterDeviceDto } from './dto/register-device.dto.js';

@Injectable()
export class DevicesService {
  constructor(private readonly prisma: PrismaService) {}

  register(ownerId: string, dto: RegisterDeviceDto): Promise<Device> {
    return this.prisma.device.create({
      data: {
        ownerId,
        type: dto.type,
        platform: dto.platform,
        model: dto.model,
        osVersion: dto.osVersion,
        appVersion: dto.appVersion,
        lastActiveAt: new Date(),
      },
    });
  }

  listForOwner(ownerId: string): Promise<Device[]> {
    return this.prisma.device.findMany({ where: { ownerId }, orderBy: { lastActiveAt: 'desc' } });
  }

  async findOneForOwner(deviceId: string, ownerId: string): Promise<Device> {
    const device = await this.prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) {
      throw new NotFoundException('Appareil introuvable.');
    }
    if (device.ownerId !== ownerId) {
      throw new ForbiddenException("Vous n'avez pas accès à cet appareil.");
    }
    return device;
  }

  async heartbeat(deviceId: string, ownerId: string): Promise<Device> {
    const device = await this.findOneForOwner(deviceId, ownerId);
    if (device.status !== 'ACTIVE') {
      throw new ForbiddenException('Cet appareil n’est plus actif.');
    }
    return this.prisma.device.update({ where: { id: deviceId }, data: { lastActiveAt: new Date() } });
  }

  async revoke(deviceId: string, ownerId: string): Promise<Device> {
    await this.findOneForOwner(deviceId, ownerId);
    return this.prisma.device.update({ where: { id: deviceId }, data: { status: 'REVOKED' } });
  }
}
