import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { UsersService } from '../users/users.service.js';
import type { AuthenticatedUser } from '../auth/jwt-auth.guard.js';
import { hasPermission, type AdminRole } from './permissions.js';
import { PERMISSION_KEY, type RequiredPermission } from './require-permission.decorator.js';

export interface AdminRequest extends Request {
  user: AuthenticatedUser;
  adminRole: AdminRole;
}

/**
 * S'applique APRÈS JwtAuthGuard (qui authentifie et attache request.user). Recharge le rôle admin
 * depuis la base à chaque requête — ne jamais faire confiance à un rôle mis en cache dans le jeton,
 * un retrait de droits doit être effectif immédiatement (§8 du cahier des charges).
 */
@Injectable()
export class AdminPermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.get<RequiredPermission | undefined>(PERMISSION_KEY, context.getHandler());
    if (!required) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AdminRequest>();
    const user = await this.usersService.findById(request.user.id);
    if (!user?.adminRole) {
      throw new ForbiddenException("Vous n'avez pas de rôle d'administration.");
    }
    if (!hasPermission(user.adminRole as AdminRole, required.resource, required.action)) {
      throw new ForbiddenException('Votre rôle ne permet pas cette action.');
    }

    request.adminRole = user.adminRole as AdminRole;
    return true;
  }
}
