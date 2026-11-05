import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CompatibilityRecord, ProjectionMode } from '../generated/prisma/client.js';

export interface CompatibilityRecordInput {
  deviceModel: string;
  accessoryModel?: string;
  osName: string;
  osVersion?: string;
  mode: ProjectionMode;
  feature: string;
  result?: CompatibilityRecord['result'];
  testedVersion?: string;
  testedAt?: Date;
}

export interface CompatibilityQuery {
  deviceModel?: string;
  accessoryModel?: string;
  mode?: ProjectionMode;
}

@Injectable()
export class CompatibilityService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Publication d'un résultat de test de compatibilité. Réservé à l'administration
   * (§7.5 du cahier des charges) — pas encore exposé via un contrôleur HTTP tant que le RBAC
   * admin n'existe pas.
   */
  createRecord(input: CompatibilityRecordInput): Promise<CompatibilityRecord> {
    return this.prisma.compatibilityRecord.create({ data: input });
  }

  query(filters: CompatibilityQuery): Promise<CompatibilityRecord[]> {
    return this.prisma.compatibilityRecord.findMany({
      where: {
        ...(filters.deviceModel ? { deviceModel: filters.deviceModel } : {}),
        ...(filters.accessoryModel ? { accessoryModel: filters.accessoryModel } : {}),
        ...(filters.mode ? { mode: filters.mode } : {}),
      },
      orderBy: { testedAt: 'desc' },
    });
  }
}
