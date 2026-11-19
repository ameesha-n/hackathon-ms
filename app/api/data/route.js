import db from '@/lib/db';
import { guard } from '@/lib/auth';
export async function GET() {
  const [u, err] = await guard(); if (err) return err;
  const [leaderboard] = await db.query('SELECT * FROM leaderboard ORDER BY rnk');
  const [teams] = await db.query(
    `SELECT t.team_id, t.team_name, GROUP_CONCAT(p.name SEPARATOR ', ') AS members FROM team t
     JOIN team_member tm ON tm.team_id = t.team_id JOIN participant p ON p.participant_id = tm.participant_id GROUP BY t.team_id, t.team_name`);
  const [[stats]] = await db.query('SELECT (SELECT COUNT(*) FROM participant) participants, (SELECT COUNT(*) FROM team) teams, (SELECT COUNT(*) FROM project) projects, (SELECT SUM(amount) FROM sponsorship WHERE hackathon_id = 1) funding');
  const audit = u.role === 'admin' ? (await db.query('SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 5'))[0] : [];
  return Response.json({ leaderboard, teams, stats, audit });
}
