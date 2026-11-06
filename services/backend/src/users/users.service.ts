import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import type { User } from '../generated/prisma/client.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  createWithPasswordHash(email: string, passwordHash: string): Promise<User> {
    return this.prisma.user.create({ data: { email, passwordHash } });
  }

  async setAdminRole(userId: string, adminRole: User['adminRole']): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable.');
    }
    return this.prisma.user.update({ where: { id: userId }, data: { adminRole } });
  }

  /** Recherche admin : par préfixe d'e-mail si fourni, sinon les comptes les plus récents. */
  search(emailQuery?: string, take = 25): Promise<User[]> {
    return this.prisma.user.findMany({
      where: emailQuery ? { email: { contains: emailQuery, mode: 'insensitive' } } : undefined,
      orderBy: { createdAt: 'desc' },
      take,
    });
  }
}
