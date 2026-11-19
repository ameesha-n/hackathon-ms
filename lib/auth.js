import jwt from 'jsonwebtoken';
import { cookies } from 'next/headers';
export const sign = u => jwt.sign(u, process.env.JWT_SECRET, { expiresIn: '8h' });
export async function currentUser() {
  const c = (await cookies()).get('token');
  try { return c ? jwt.verify(c.value, process.env.JWT_SECRET) : null; } catch { return null; }
}
// RBAC guard: returns [user, errorResponse]
export async function guard(...roles) {
  const u = await currentUser();
  if (!u) return [null, Response.json({ error: 'Login required' }, { status: 401 })];
  if (roles.length && !roles.includes(u.role)) return [null, Response.json({ error: 'Forbidden for role ' + u.role }, { status: 403 })];
  return [u, null];
}
