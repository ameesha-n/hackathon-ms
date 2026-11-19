import db from '@/lib/db';
import { guard } from '@/lib/auth';
export async function POST(req) {
  const [u, err] = await guard('participant'); if (err) return err;
  const { team_name } = await req.json();
  try { await db.query('CALL sp_register_team(?, 1, ?)', [team_name, u.participant_id]); return Response.json({ ok: true }); }
  catch (e) { return Response.json({ error: e.sqlMessage || 'Failed' }, { status: 400 }); }
}
