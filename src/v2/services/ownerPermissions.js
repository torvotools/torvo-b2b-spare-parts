import { requireBackend } from './supabase';

// Owner-only RPCs enforce authorization on the server; never trust client-side role flags.
const rpc = async (name, args = {}) => {
  const { data, error } = await requireBackend().rpc(name, args);
  if (error) throw error;
  return data;
};

const uuid = value => {
  const id = String(value ?? '').trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
    throw new Error('VALID STAFF ID REQUIRED');
  }
  return id;
};

export async function listOwnerStaffPermissions(staffUserId = null) {
  return rpc('owner_list_staff_permissions', { p_staff_user_id: staffUserId == null ? null : uuid(staffUserId) });
}

export async function grantOwnerStaffPermission(staffUserId, permission, reason, expiresAt = null) {
  const key = String(permission ?? '').trim();
  const why = String(reason ?? '').trim();
  if (!/^[a-z][a-z0-9_]*([.][a-z][a-z0-9_]*)+$/.test(key)) throw new Error('VALID PERMISSION REQUIRED');
  if (why.length < 5 || why.length > 500) throw new Error('REASON MUST BE 5-500 CHARACTERS');
  const expiry = expiresAt == null || expiresAt === '' ? null : new Date(expiresAt);
  if (expiry && (!Number.isFinite(expiry.getTime()) || expiry.getTime() <= Date.now())) throw new Error('FUTURE EXPIRY REQUIRED');
  return rpc('owner_grant_staff_permission', {
    p_staff_user_id: uuid(staffUserId), p_permission: key,
    p_reason: why, p_valid_until: expiry ? expiry.toISOString() : null,
  });
}

export async function revokeOwnerStaffPermission(grantId, reason) {
  const why = String(reason ?? '').trim();
  if (why.length < 5 || why.length > 500) throw new Error('REASON MUST BE 5-500 CHARACTERS');
  return rpc('owner_revoke_staff_permission', { p_grant_id: uuid(grantId), p_reason: why });
}

export async function hasOwnerStaffPermission(permission) {
  return rpc('owner_has_staff_permission', { p_permission: String(permission ?? '').trim() });
}
