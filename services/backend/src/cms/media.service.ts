import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { Media } from '../generated/prisma/client.js';

export interface RegisterMediaInput {
  filename: string;
  url: string;
  mimeType: string;
  sizeBytes: number;
  altText?: string;
}

/**
 * Catalogue de métadonnées média uniquement : l'upload du fichier lui-même (stockage objet/CDN)
 * n'est pas encore intégré. `url` doit déjà pointer vers un fichier accessible.
 */
@Injectable()
export class MediaService {
  constructor(private readonly prisma: PrismaService) {}

  register(input: RegisterMediaInput): Promise<Media> {
    return this.prisma.media.create({ data: input });
  }

  list(): Promise<Media[]> {
    return this.prisma.media.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async remove(id: string): Promise<Media> {
    const media = await this.prisma.media.findUnique({ where: { id } });
    if (!media) {
      throw new NotFoundException('Média introuvable.');
    }
    return this.prisma.media.delete({ where: { id } });
  }
}
