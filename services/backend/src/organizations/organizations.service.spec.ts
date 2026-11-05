import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { OrganizationsService } from './organizations.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UsersService } from '../users/users.service.js';

describe('OrganizationsService', () => {
  let service: OrganizationsService;
  let prisma: {
    organization: { create: ReturnType<typeof vi.fn>; findUnique: ReturnType<typeof vi.fn> };
    organizationMember: {
      findUnique: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
  };
  let usersService: { findByEmail: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    prisma = {
      organization: { create: vi.fn(), findUnique: vi.fn() },
      organizationMember: {
        findUnique: vi.fn(),
        findMany: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
      },
    };
    usersService = { findByEmail: vi.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrganizationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: UsersService, useValue: usersService },
      ],
    }).compile();

    service = module.get<OrganizationsService>(OrganizationsService);
  });

  describe('create', () => {
    it('creates the organization with the creator as OWNER', async () => {
      prisma.organization.create.mockResolvedValueOnce({ id: 'org-1', name: 'Acme', ownerId: 'user-1' });

      const result = await service.create('user-1', 'Acme');

      expect(result).toEqual({ id: 'org-1', name: 'Acme', ownerId: 'user-1' });
      expect(prisma.organization.create).toHaveBeenCalledWith({
        data: {
          name: 'Acme',
          ownerId: 'user-1',
          members: { create: { userId: 'user-1', role: 'OWNER', status: 'ACTIVE', joinedAt: expect.any(Date) } },
        },
      });
    });
  });

  describe('findByIdForMember', () => {
    it('rejects a non-member', async () => {
      prisma.organizationMember.findUnique.mockResolvedValueOnce(null);

      await expect(service.findByIdForMember('org-1', 'user-2')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('returns the organization for an active member', async () => {
      prisma.organizationMember.findUnique.mockResolvedValueOnce({ status: 'ACTIVE', role: 'MEMBER' });
      prisma.organization.findUnique.mockResolvedValueOnce({ id: 'org-1', name: 'Acme' });

      await expect(service.findByIdForMember('org-1', 'user-1')).resolves.toEqual({ id: 'org-1', name: 'Acme' });
    });
  });

  describe('inviteMember', () => {
    it('rejects when the requester is not an owner or admin', async () => {
      prisma.organizationMember.findUnique.mockResolvedValueOnce({ status: 'ACTIVE', role: 'MEMBER' });

      await expect(service.inviteMember('org-1', 'user-1', 'new@b.com', 'MEMBER')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects when the invitee has no account', async () => {
      prisma.organizationMember.findUnique.mockResolvedValueOnce({ status: 'ACTIVE', role: 'OWNER' });
      usersService.findByEmail.mockResolvedValueOnce(null);

      await expect(service.inviteMember('org-1', 'user-1', 'ghost@b.com', 'MEMBER')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rejects when the invitee is already a member', async () => {
      prisma.organizationMember.findUnique
        .mockResolvedValueOnce({ status: 'ACTIVE', role: 'OWNER' })
        .mockResolvedValueOnce({ id: 'member-1' });
      usersService.findByEmail.mockResolvedValueOnce({ id: 'user-2', email: 'new@b.com' });

      await expect(service.inviteMember('org-1', 'user-1', 'new@b.com', 'MEMBER')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('creates an INVITED membership for a valid request', async () => {
      prisma.organizationMember.findUnique
        .mockResolvedValueOnce({ status: 'ACTIVE', role: 'OWNER' })
        .mockResolvedValueOnce(null);
      usersService.findByEmail.mockResolvedValueOnce({ id: 'user-2', email: 'new@b.com' });
      prisma.organizationMember.create.mockResolvedValueOnce({ id: 'member-2', status: 'INVITED' });

      const result = await service.inviteMember('org-1', 'user-1', 'new@b.com', 'MEMBER');

      expect(result).toEqual({ id: 'member-2', status: 'INVITED' });
      expect(prisma.organizationMember.create).toHaveBeenCalledWith({
        data: { organizationId: 'org-1', userId: 'user-2', role: 'MEMBER', status: 'INVITED' },
      });
    });
  });

  describe('removeMember', () => {
    it('refuses to remove the owner', async () => {
      prisma.organizationMember.findUnique
        .mockResolvedValueOnce({ status: 'ACTIVE', role: 'ADMIN' })
        .mockResolvedValueOnce({ id: 'member-1', role: 'OWNER' });

      await expect(service.removeMember('org-1', 'user-1', 'owner-id')).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('removes a regular member when requested by a manager', async () => {
      prisma.organizationMember.findUnique
        .mockResolvedValueOnce({ status: 'ACTIVE', role: 'OWNER' })
        .mockResolvedValueOnce({ id: 'member-2', role: 'MEMBER' });
      prisma.organizationMember.update.mockResolvedValueOnce({ id: 'member-2', status: 'REMOVED' });

      const result = await service.removeMember('org-1', 'user-1', 'user-2');

      expect(result).toEqual({ id: 'member-2', status: 'REMOVED' });
      expect(prisma.organizationMember.update).toHaveBeenCalledWith({
        where: { id: 'member-2' },
        data: { status: 'REMOVED' },
      });
    });
  });
});
