import { ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { JwtAuthGuard } from './jwt-auth.guard.js';

function makeContext(headers: Record<string, string>) {
  const request: { headers: Record<string, string>; user?: unknown } = { headers };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext & { request: typeof request };
}

describe('JwtAuthGuard', () => {
  let jwtService: { verifyAsync: ReturnType<typeof vi.fn> };
  let guard: JwtAuthGuard;

  beforeEach(() => {
    jwtService = { verifyAsync: vi.fn() };
    guard = new JwtAuthGuard(jwtService as unknown as JwtService);
  });

  it('rejects requests without an Authorization header', async () => {
    const context = makeContext({});
    await expect(guard.canActivate(context)).rejects.toThrow('Jeton');
  });

  it('rejects an invalid or expired token', async () => {
    jwtService.verifyAsync.mockRejectedValueOnce(new Error('expired'));
    const context = makeContext({ authorization: 'Bearer bad-token' });
    await expect(guard.canActivate(context)).rejects.toThrow('invalide');
  });

  it('attaches the decoded user and allows the request through for a valid token', async () => {
    jwtService.verifyAsync.mockResolvedValueOnce({ sub: 'user-1', email: 'a@b.com' });
    const context = makeContext({ authorization: 'Bearer good-token' });

    await expect(guard.canActivate(context)).resolves.toBe(true);

    const request = context.switchToHttp().getRequest() as { user?: { id: string; email: string } };
    expect(request.user).toEqual({ id: 'user-1', email: 'a@b.com' });
  });
});
