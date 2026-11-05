import { IsIn, IsOptional } from 'class-validator';
import { ADMIN_ROLES } from '../../rbac/permissions.js';

export class UpdateAdminRoleDto {
  @IsOptional()
  @IsIn(ADMIN_ROLES)
  adminRole?: (typeof ADMIN_ROLES)[number] | null;
}
