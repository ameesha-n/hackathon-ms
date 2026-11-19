import db from '@/lib/db';
import { guard } from '@/lib/auth';
export async function POST(req) {
  const [u, err] = await guard('judge'); if (err) return err;
  const { project_id, innovation, technical, impact } = await req.json();
  await db.query(
    `INSERT INTO score VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE innovation=VALUES(innovation), technical=VALUES(technical), impact=VALUES(impact)`,
    [project_id, u.judge_id, innovation, technical, impact]);
  return Response.json({ ok: true });
}
