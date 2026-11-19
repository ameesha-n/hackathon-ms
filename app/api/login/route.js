import bcrypt from 'bcryptjs';
import db from '@/lib/db';
import { sign, currentUser } from '@/lib/auth';
export async function POST(req) {
  const { email, password } = await req.json();
  const [[u]] = await db.query(
    'SELECT u.user_id, u.email, u.password_hash, r.role_name AS role, u.participant_id, u.judge_id, u.mentor_id FROM app_user u JOIN role r ON r.role_id = u.role_id WHERE u.email = ?', [email]);
  if (!u || !(await bcrypt.compare(password, u.password_hash))) return Response.json({ error: 'Invalid credentials' }, { status: 401 });
  const { password_hash, ...safe } = u;
  const res = Response.json(safe);
  res.headers.append('Set-Cookie', `token=${sign(safe)}; HttpOnly; Path=/; SameSite=Lax; Max-Age=28800`);
  return res;
}
export async function GET() { return Response.json((await currentUser()) || { error: 'none' }); }
export async function DELETE() {
  const res = Response.json({ ok: true });
  res.headers.append('Set-Cookie', 'token=; HttpOnly; Path=/; Max-Age=0'); return res;
}
