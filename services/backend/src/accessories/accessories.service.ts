import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { Accessory } from '../generated/prisma/client.js';

export interface CatalogEntryInput {
  serialNumber: string;
  model: string;
  firmwareVersion?: string;
  batchNumber?: string;
  warrantyExpiresAt?: Date;
}

@Injectable()
export class AccessoriesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Création d'une fiche accessoire en stock. Réservé à l'administration (§7.5 du cahier des
   * charges) — pas encore exposé via un contrôleur HTTP tant que le RBAC admin n'existe pas.
   */
  async registerCatalogEntry(input: CatalogEntryInput): Promise<Accessory> {
    const existing = await this.prisma.accessory.findUnique({ where: { serialNumber: input.serialNumber } });
    if (existing) {
      throw new ConflictException('Un accessoire avec ce numéro de série existe déjà.');
    }

    return this.prisma.accessory.create({
      data: {
        serialNumber: input.serialNumber,
        model: input.model,
        firmwareVersion: input.firmwareVersion,
        batchNumber: input.batchNumber,
        warrantyExpiresAt: input.warrantyExpiresAt,
      },
    });
  }

  async claim(ownerId: string, serialNumber: string): Promise<Accessory> {
    const accessory = await this.prisma.accessory.findUnique({ where: { serialNumber } });
    if (!accessory) {
      throw new NotFoundException('Aucun accessoire ne correspond à ce numéro de série.');
    }
    if (accessory.ownerId) {
      throw new ConflictException('Cet accessoire est déjà associé à un compte.');
    }

    return this.prisma.accessory.update({
      where: { id: accessory.id },
      data: { ownerId, saleStatus: 'SOLD' },
    });
  }

  listForOwner(ownerId: string): Promise<Accessory[]> {
    return this.prisma.accessory.findMany({ where: { ownerId } });
  }

  async release(accessoryId: string, ownerId: string): Promise<Accessory> {
    const accessory = await this.prisma.accessory.findUnique({ where: { id: accessoryId } });
    if (!accessory) {
      throw new NotFoundException('Accessoire introuvable.');
    }
    if (accessory.ownerId !== ownerId) {
      throw new ForbiddenException("Vous n'avez pas accès à cet accessoire.");
    }

    return this.prisma.accessory.update({ where: { id: accessoryId }, data: { ownerId: null } });
  }
}
