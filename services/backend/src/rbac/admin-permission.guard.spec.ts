import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdminPermissionGuard } from './admin-permission.guard.js';
import { UsersService } from '../users/users.service.js';

function makeContext(request: { user: { id: string; email: string }; adminRole?: string }) {
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => () => undefined,
  } as unknown as ExecutionContext;
}

describe('AdminPermissionGuard', () => {
  let reflector: { get: ReturnType<typeof vi.fn> };
  let usersService: { findById: ReturnType<typeof vi.fn> };
  let guard: AdminPermissionGuard;

  beforeEach(() => {
    reflector = { get: vi.fn() };
    usersService = { findById: vi.fn() };
    guard = new AdminPermissionGuard(reflector as unknown as Reflector, usersService as unknown as UsersService);
  });

  it('allows the request through when the route requires no permission', async () => {
    reflector.get.mockReturnValueOnce(undefined);
    const context = makeContext({ user: { id: 'user-1', email: 'a@b.com' } });

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('rejects a user with no admin role', async () => {
    reflector.get.mockReturnValueOnce({ resource: 'accessories', action: 'create' });
    usersService.findById.mockResolvedValueOnce({ id: 'user-1', adminRole: null });
    const context = makeContext({ user: { id: 'user-1', email: 'a@b.com' } });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects an admin role without the required permission', async () => {
    reflector.get.mockReturnValueOnce({ resource: 'users', action: 'approve' });
    usersService.findById.mockResolvedValueOnce({ id: 'user-1', adminRole: 'SUPPORT_AGENT' });
    const context = makeContext({ user: { id: 'user-1', email: 'a@b.com' } });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows and attaches the admin role when permitted', async () => {
    reflector.get.mockReturnValueOnce({ resource: 'accessories', action: 'create' });
    usersService.findById.mockResolvedValueOnce({ id: 'user-1', adminRole: 'TECHNICAL_OPERATOR' });
    const request = { user: { id: 'user-1', email: 'a@b.com' } } as { user: { id: string; email: string }; adminRole?: string };
    const context = makeContext(request);

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.adminRole).toBe('TECHNICAL_OPERATOR');
  });
});
