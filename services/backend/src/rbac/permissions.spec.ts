import { describe, it, expect } from 'vitest';
import { hasPermission } from './permissions.js';

describe('hasPermission', () => {
  it('grants SUPER_ADMIN every action on every known resource', () => {
    expect(hasPermission('SUPER_ADMIN', 'accessories', 'delete')).toBe(true);
    expect(hasPermission('SUPER_ADMIN', 'users', 'approve')).toBe(true);
    expect(hasPermission('SUPER_ADMIN', 'audit', 'export')).toBe(true);
  });

  it('lets TECHNICAL_OPERATOR manage accessories and compatibility but not users', () => {
    expect(hasPermission('TECHNICAL_OPERATOR', 'accessories', 'create')).toBe(true);
    expect(hasPermission('TECHNICAL_OPERATOR', 'compatibility', 'update')).toBe(true);
    expect(hasPermission('TECHNICAL_OPERATOR', 'users', 'read')).toBe(false);
  });

  it('restricts READ_ONLY_AUDITOR to read and export, never write', () => {
    expect(hasPermission('READ_ONLY_AUDITOR', 'accessories', 'read')).toBe(true);
    expect(hasPermission('READ_ONLY_AUDITOR', 'audit', 'export')).toBe(true);
    expect(hasPermission('READ_ONLY_AUDITOR', 'accessories', 'create')).toBe(false);
  });

  it('gives FINANCE_MANAGER no access to accessories or compatibility', () => {
    expect(hasPermission('FINANCE_MANAGER', 'accessories', 'read')).toBe(false);
    expect(hasPermission('FINANCE_MANAGER', 'compatibility', 'read')).toBe(false);
  });

  it('lets CONTENT_MANAGER manage the CMS but not accessories', () => {
    expect(hasPermission('CONTENT_MANAGER', 'cms', 'create')).toBe(true);
    expect(hasPermission('CONTENT_MANAGER', 'cms', 'approve')).toBe(true);
    expect(hasPermission('CONTENT_MANAGER', 'accessories', 'read')).toBe(false);
  });

  it('gives TECHNICAL_OPERATOR no access to the CMS', () => {
    expect(hasPermission('TECHNICAL_OPERATOR', 'cms', 'read')).toBe(false);
  });
});
