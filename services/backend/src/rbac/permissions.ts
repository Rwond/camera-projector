/**
 * Matrice de permissions RBAC (§8 du cahier des charges). Statique pour l'instant : les 7 rôles
 * du cahier des charges sont fixes, pas de rôles personnalisés. À faire évoluer vers une table si
 * le besoin de rôles configurables apparaît.
 */

export const ADMIN_ROLES = [
  'SUPER_ADMIN',
  'PRODUCT_MANAGER',
  'SUPPORT_AGENT',
  'FINANCE_MANAGER',
  'TECHNICAL_OPERATOR',
  'CONTENT_MANAGER',
  'READ_ONLY_AUDITOR',
] as const;
export type AdminRole = (typeof ADMIN_ROLES)[number];

export const RESOURCES = [
  'users',
  'accessories',
  'compatibility',
  'audit',
  'cms',
  'support',
  'notifications',
] as const;
export type Resource = (typeof RESOURCES)[number];

export type Action = 'read' | 'create' | 'update' | 'delete' | 'export' | 'approve';

const ALL_ACTIONS: Action[] = ['read', 'create', 'update', 'delete', 'export', 'approve'];

export const PERMISSIONS: Record<AdminRole, Partial<Record<Resource, Action[]>>> = {
  SUPER_ADMIN: {
    users: ALL_ACTIONS,
    accessories: ALL_ACTIONS,
    compatibility: ALL_ACTIONS,
    audit: ALL_ACTIONS,
    cms: ALL_ACTIONS,
    support: ALL_ACTIONS,
    notifications: ALL_ACTIONS,
  },
  PRODUCT_MANAGER: {
    users: ['read'],
    accessories: ['read', 'create', 'update'],
    compatibility: ['read', 'create', 'update'],
    audit: ['read'],
    cms: ['read'],
  },
  SUPPORT_AGENT: {
    users: ['read'],
    audit: ['read'],
    support: ['read', 'create', 'update'],
    notifications: ['read'],
  },
  FINANCE_MANAGER: {
    audit: ['read'],
  },
  TECHNICAL_OPERATOR: {
    accessories: ['read', 'create', 'update'],
    compatibility: ['read', 'create', 'update'],
    audit: ['read'],
  },
  CONTENT_MANAGER: {
    audit: ['read'],
    cms: ['read', 'create', 'update', 'delete', 'approve'],
  },
  READ_ONLY_AUDITOR: {
    users: ['read'],
    accessories: ['read'],
    compatibility: ['read'],
    audit: ['read', 'export'],
    cms: ['read'],
    support: ['read'],
    notifications: ['read'],
  },
};

export function hasPermission(role: AdminRole, resource: Resource, action: Action): boolean {
  return PERMISSIONS[role][resource]?.includes(action) ?? false;
}
