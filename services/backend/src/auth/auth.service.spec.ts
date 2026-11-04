import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service.js';
import { UsersService } from '../users/users.service.js';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: {
    findByEmail: ReturnType<typeof vi.fn>;
    createWithPasswordHash: ReturnType<typeof vi.fn>;
  };
  let jwtService: { signAsync: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    usersService = { findByEmail: vi.fn(), createWithPasswordHash: vi.fn() };
    jwtService = { signAsync: vi.fn().mockResolvedValue('signed-token') };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('register', () => {
    it('rejects registration when the e-mail is already used', async () => {
      usersService.findByEmail.mockResolvedValueOnce({ id: '1', email: 'a@b.com' });

      await expect(service.register({ email: 'a@b.com', password: 'longenough1' })).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(usersService.createWithPasswordHash).not.toHaveBeenCalled();
    });

    it('hashes the password and issues tokens for a new account', async () => {
      usersService.findByEmail.mockResolvedValueOnce(null);
      usersService.createWithPasswordHash.mockImplementationOnce(async (email: string, hash: string) => ({
        id: '1',
        email,
        passwordHash: hash,
      }));

      const tokens = await service.register({ email: 'a@b.com', password: 'longenough1' });

      expect(tokens).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
      const [, storedHash] = usersService.createWithPasswordHash.mock.calls[0];
      await expect(bcrypt.compare('longenough1', storedHash)).resolves.toBe(true);
    });
  });

  describe('login', () => {
    it('rejects an unknown e-mail', async () => {
      usersService.findByEmail.mockResolvedValueOnce(null);

      await expect(service.login({ email: 'a@b.com', password: 'x' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rejects an incorrect password', async () => {
      const passwordHash = await bcrypt.hash('correct-password', 4);
      usersService.findByEmail.mockResolvedValueOnce({ id: '1', email: 'a@b.com', passwordHash });

      await expect(service.login({ email: 'a@b.com', password: 'wrong-password' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('issues tokens for correct credentials', async () => {
      const passwordHash = await bcrypt.hash('correct-password', 4);
      usersService.findByEmail.mockResolvedValueOnce({ id: '1', email: 'a@b.com', passwordHash });

      const tokens = await service.login({ email: 'a@b.com', password: 'correct-password' });

      expect(tokens).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
    });
  });
});
