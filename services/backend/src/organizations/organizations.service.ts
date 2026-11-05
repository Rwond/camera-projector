import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';
import type { Organization, OrganizationMember } from '../generated/prisma/client.js';

const MANAGING_ROLES = ['OWNER', 'ADMIN'] as const;

@Injectable()
export class OrganizationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
  ) {}

  async create(ownerId: string, name: string): Promise<Organization> {
    return this.prisma.organization.create({
      data: {
        name,
        ownerId,
        members: {
          create: { userId: ownerId, role: 'OWNER', status: 'ACTIVE', joinedAt: new Date() },
        },
      },
    });
  }

  async findByIdForMember(organizationId: string, requestingUserId: string): Promise<Organization> {
    await this.requireActiveMembership(organizationId, requestingUserId);
    const organization = await this.prisma.organization.findUnique({ where: { id: organizationId } });
    if (!organization) {
      throw new NotFoundException('Organisation introuvable.');
    }
    return organization;
  }

  async listMembers(organizationId: string, requestingUserId: string): Promise<OrganizationMember[]> {
    await this.requireActiveMembership(organizationId, requestingUserId);
    return this.prisma.organizationMember.findMany({ where: { organizationId } });
  }

  async inviteMember(
    organizationId: string,
    invitedByUserId: string,
    inviteeEmail: string,
    role: 'ADMIN' | 'MEMBER',
  ): Promise<OrganizationMember> {
    await this.requireManagingRole(organizationId, invitedByUserId);

    const invitee = await this.usersService.findByEmail(inviteeEmail);
    if (!invitee) {
      throw new NotFoundException('Aucun compte ne correspond à cette adresse e-mail.');
    }

    const existingMembership = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId, userId: invitee.id } },
    });
    if (existingMembership) {
      throw new ConflictException('Cet utilisateur est déjà membre ou invité dans cette organisation.');
    }

    return this.prisma.organizationMember.create({
      data: { organizationId, userId: invitee.id, role, status: 'INVITED' },
    });
  }

  async acceptInvite(organizationId: string, userId: string): Promise<OrganizationMember> {
    const membership = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId, userId } },
    });
    if (!membership || membership.status !== 'INVITED') {
      throw new NotFoundException('Aucune invitation en attente pour cette organisation.');
    }

    return this.prisma.organizationMember.update({
      where: { id: membership.id },
      data: { status: 'ACTIVE', joinedAt: new Date() },
    });
  }

  async removeMember(
    organizationId: string,
    requestedByUserId: string,
    targetUserId: string,
  ): Promise<OrganizationMember> {
    await this.requireManagingRole(organizationId, requestedByUserId);

    const target = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId, userId: targetUserId } },
    });
    if (!target) {
      throw new NotFoundException('Ce membre ne fait pas partie de cette organisation.');
    }
    if (target.role === 'OWNER') {
      throw new ForbiddenException("Le propriétaire de l'organisation ne peut pas être retiré.");
    }

    return this.prisma.organizationMember.update({
      where: { id: target.id },
      data: { status: 'REMOVED' },
    });
  }

  private async requireActiveMembership(organizationId: string, userId: string): Promise<OrganizationMember> {
    const membership = await this.prisma.organizationMember.findUnique({
      where: { organizationId_userId: { organizationId, userId } },
    });
    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException("Vous n'avez pas accès à cette organisation.");
    }
    return membership;
  }

  private async requireManagingRole(organizationId: string, userId: string): Promise<OrganizationMember> {
    const membership = await this.requireActiveMembership(organizationId, userId);
    if (!MANAGING_ROLES.includes(membership.role as (typeof MANAGING_ROLES)[number])) {
      throw new ForbiddenException('Seuls les propriétaires ou administrateurs peuvent effectuer cette action.');
    }
    return membership;
  }
}
