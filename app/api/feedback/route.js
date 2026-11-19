import db from '@/lib/db';
import { guard } from '@/lib/auth';

export async function GET() {                           // any logged-in user can read
  const [, err] = await guard(); if (err) return err;
  const [summary] = await db.query('SELECT * FROM project_feedback ORDER BY avg_rating DESC');
  const [recent] = await db.query(
    `SELECT f.feedback_id, p.title, m.name AS mentor, f.rating, f.comment
     FROM feedback f JOIN project p ON p.project_id = f.project_id
     JOIN mentor m ON m.mentor_id = f.mentor_id
     ORDER BY f.feedback_id DESC LIMIT 8`);
  return Response.json({ summary, recent });
}

export async function POST(req) {                       // only the mentor role can write
  const [u, err] = await guard('mentor'); if (err) return err;
  const { project_id, rating, comment } = await req.json();
  try {
    await db.query('INSERT INTO feedback (project_id, mentor_id, rating, comment) VALUES (?,?,?,?)',
      [project_id, u.mentor_id, rating, comment]);
    return Response.json({ ok: true });
  } catch (e) { return Response.json({ error: e.sqlMessage || 'Failed' }, { status: 400 }); }
}
